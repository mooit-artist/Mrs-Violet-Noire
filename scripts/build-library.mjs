#!/usr/bin/env node
/**
 * build-library.mjs — build data/books.json from the book-list sheet
 *
 * Runs in GitHub Actions whenever the inputs change
 * (see .github/workflows/build-library.yml). Node 20+, no dependencies.
 *
 * Inputs:
 *   data/book-list.json                The book-list Google Sheet, written by
 *                                      scripts/import-book-list.mjs. This decides
 *                                      which books appear on the site:
 *                                        owned -> The Library
 *                                        tbr   -> Up Next
 *   data/goodreads_library_export.csv  Optional. Used only to enrich matching books
 *                                      with Goodreads ratings, dates, ISBNs and links.
 *   data/notes.json                    Optional. Mrs. Noire's blurbs and hand-picked
 *                                      Amazon links, keyed by Goodreads Book Id.
 *   data/covers.json                   Optional cache of checked Open Library covers.
 *
 * Output:
 *   data/books.json                    what the home page renders. Each book has
 *                                      list: "library" | "upnext".
 *
 * Env:
 *   AMAZON_TAG      Amazon Associates tracking ID. Empty or unset = plain Amazon
 *                   links with no affiliate tag (any tag in notes.json is removed).
 *   LOOKUP_COVERS   "1" to check covers for books not yet in data/covers.json:
 *                   the ISBN cover first, then an Open Library title + author
 *                   search (network; failures are ignored).
 *
 * Behaviour:
 *   - A book on both tabs appears only in Up Next.
 *   - A malformed input exits non-zero and leaves the existing books.json alone.
 */

import { readFile, writeFile, rename, mkdir } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const LIST_FILE = resolve(ROOT, 'data', 'book-list.json');
const CSV_FILE = resolve(ROOT, 'data', 'goodreads_library_export.csv');
const NOTES_FILE = resolve(ROOT, 'data', 'notes.json');
const COVERS_FILE = resolve(ROOT, 'data', 'covers.json');
const OUT_FILE = resolve(ROOT, 'data', 'books.json');
const TAG = (process.env.AMAZON_TAG || '').trim();
const LOOKUP = process.env.LOOKUP_COVERS === '1';

// RFC 4180 parser: quoted fields, doubled quotes and newlines inside quotes.
function parseCSV(text) {
  const rows = [];
  let row = [], field = '', inQuotes = false;
  text = text.replace(/^\uFEFF/, '');
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (inQuotes) {
      if (c === '"') {
        if (text[i + 1] === '"') { field += '"'; i++; } else inQuotes = false;
      } else field += c;
    } else if (c === '"') inQuotes = true;
    else if (c === ',') { row.push(field); field = ''; }
    else if (c === '\n' || c === '\r') {
      if (c === '\r' && text[i + 1] === '\n') i++;
      row.push(field); field = '';
      if (row.length > 1 || row[0] !== '') rows.push(row);
      row = [];
    } else field += c;
  }
  if (field !== '' || row.length) { row.push(field); rows.push(row); }
  if (inQuotes) throw new Error('unterminated quoted field in CSV');
  const [header = [], ...body] = rows;
  return body.map(r => Object.fromEntries(header.map((h, i) => [h.trim(), (r[i] ?? '').trim()])));
}

const digits = s => String(s || '').replace(/[^0-9Xx]/g, '').toUpperCase();
const num = s => (s === '' || s == null || Number.isNaN(Number(s)) ? null : Number(s));
const grDate = s => (/^\d{4}\/\d{2}\/\d{2}$/.test(s || '') ? s.replace(/\//g, '-') : null);

function splitSeries(title) {
  const m = /^(.*?)\s*\(([^()]*#[^()]*)\)\s*$/.exec(title);
  return m ? { title: m[1].trim(), series: m[2].trim() } : { title: title.trim(), series: null };
}

// ── Matching sheet rows to Goodreads books ──────────────────────────────────
// Titles are compared without subtitles, series and punctuation; authors by
// surname. A small edit distance absorbs typos in the sheet
// ("happended", "Cavanaugh").
const norm = s => String(s || '').toLowerCase().normalize('NFKD')
  .replace(/[\u0300-\u036f]/g, '').replace(/&/g, 'and').replace(/[^a-z0-9]+/g, ' ').trim();
const shortTitle = t => norm(String(t || '').replace(/\s*\([^)]*\)\s*$/, '').split(/[:;]/)[0]).replace(/^(the|a|an) /, '');
const surname = a => { const w = norm(a).split(' ').filter(Boolean); return w[w.length - 1] || ''; };

function lev(a, b) {
  if (a === b) return 0;
  const prev = Array.from({ length: b.length + 1 }, (_, i) => i);
  for (let i = 1; i <= a.length; i++) {
    let diag = prev[0];
    prev[0] = i;
    for (let j = 1; j <= b.length; j++) {
      const tmp = prev[j];
      prev[j] = Math.min(prev[j] + 1, prev[j - 1] + 1, diag + (a[i - 1] === b[j - 1] ? 0 : 1));
      diag = tmp;
    }
  }
  return prev[b.length];
}
const close = (a, b, ratio) => a && b && lev(a, b) <= Math.floor(Math.max(a.length, b.length) * ratio);

function findGoodreads(book, gr) {
  if (book.isbn) {
    const hit = gr.find(g => g.isbn10 === book.isbn || g.isbn13 === book.isbn);
    if (hit) return hit;
  }
  const t = shortTitle(book.title), s = surname(book.author);
  const sameAuthor = g => !s || close(g.surname, s, 0.25);
  return gr.find(g => g.short === t && sameAuthor(g))
      || gr.find(g => close(g.short, t, 0.15) && sameAuthor(g))
      // "Kill for Me" on the sheet vs "Kill for Me, Kill for You" on Goodreads
      || gr.find(g => s && close(g.surname, s, 0.25) && t.length >= 8 && g.short.startsWith(t + ' '))
      || null;
}

const search = (title, author) => encodeURIComponent(`${title} ${author || ''}`.trim()).replace(/%20/g, '+');

// Add the Associates tag when AMAZON_TAG is set; otherwise strip any tag so
// the links are plain Amazon links.
function withTag(href) {
  const u = new URL(href);
  u.searchParams.delete('tag');
  if (TAG) u.searchParams.set('tag', TAG);
  return u.toString();
}

function amazonUrl(note, isbn10, title, author) {
  if (note?.amazon && /^https:\/\/www\.amazon\.com\//.test(note.amazon)) return withTag(note.amazon);
  // For print books the ISBN-10 is also the Amazon ASIN.
  if (isbn10 && isbn10.length === 10) return withTag(`https://www.amazon.com/dp/${isbn10}`);
  return withTag(`https://www.amazon.com/s?k=${search(title, author)}&i=stripbooks`);
}

// ISBN-13 (978 prefix) -> ISBN-10, so sheet ISBNs can make direct Amazon links.
function toIsbn10(i13) {
  if (!i13 || i13.length !== 13 || !i13.startsWith('978')) return null;
  const core = i13.slice(3, 12);
  let sum = 0;
  for (let i = 0; i < 9; i++) sum += (10 - i) * Number(core[i]);
  const check = (11 - (sum % 11)) % 11;
  return core + (check === 10 ? 'X' : String(check));
}

const coverKey = b => `${norm(b.title)}|${norm(b.author)}`;

// Title searches only count when the author and title both line up, so a
// book with no author on the sheet keeps the typographic jacket rather than
// someone else's cover.
async function lookupCover(book) {
  if (!book.author) return '';
  const t = shortTitle(book.title), s = surname(book.author);
  const q = new URLSearchParams({ title: book.title.split(/[:;]/)[0], author: book.author, limit: '10', fields: 'cover_i,author_name,title' });
  const res = await fetch(`https://openlibrary.org/search.json?${q}`, {
    headers: { 'User-Agent': 'mrsvioletnoire.com library builder (github.com/mooit-artist/Mrs-Violet-Noire)' },
    signal: AbortSignal.timeout(15000),
  });
  if (!res.ok) throw new Error(`Open Library ${res.status}`);
  const { docs = [] } = await res.json();
  const doc = docs.find(d => d.cover_i &&
    close(shortTitle(d.title), t, 0.15) &&
    (d.author_name || []).some(a => close(surname(a), s, 0.25)));
  return doc ? `https://covers.openlibrary.org/b/id/${doc.cover_i}-M.jpg` : '';
}

// Open Library answers a missing ISBN cover with a 404, and a few ids with a
// tiny "no image" placeholder. Treat both as no cover.
async function usable(url) {
  const res = await fetch(url, { signal: AbortSignal.timeout(15000), redirect: 'follow' });
  if (!res.ok) return false;
  return (await res.arrayBuffer()).byteLength > 2000;
}

function isbnCover(entry, g) {
  const i = entry.isbn || g?.isbn13 || g?.isbn10;
  return i ? `https://covers.openlibrary.org/b/isbn/${i}-M.jpg?default=false` : null;
}

function toBook(entry, list, g, notes, covers) {
  const note = g ? notes[g.id] || null : null;
  const { title, series } = splitSeries(entry.title);
  const author = entry.author || g?.author || '';
  const isbn13 = (entry.isbn?.length === 13 ? entry.isbn : null) || g?.isbn13 || null;
  const isbn10 = (entry.isbn?.length === 10 ? entry.isbn : null) || g?.isbn10 || toIsbn10(isbn13);
  const coverIsbn = isbn13 || isbn10;
  const cached = covers[coverKey(entry)];
  return {
    id: g?.id || `sheet-${coverKey(entry).replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')}`,
    list,
    title,
    series: series || g?.series || null,
    author,
    format: entry.format || null,
    myRating: entry.rating || g?.myRating || null,
    avgRating: g?.avgRating ?? null,
    year: g?.year ?? null,
    pages: g?.pages ?? null,
    dateRead: g?.dateRead || null,
    dateAdded: entry.dateAdded || g?.dateAdded || null,
    blurb: note?.blurb || null,
    // data/covers.json holds the checked cover for each book ('' = none found).
    cover: cached !== undefined ? (cached || null)
         : (coverIsbn ? `https://covers.openlibrary.org/b/isbn/${coverIsbn}-M.jpg?default=false` : null),
    amazon: amazonUrl(note, isbn10, title, author),
    goodreads: g ? `https://www.goodreads.com/book/show/${encodeURIComponent(g.id)}`
                 : `https://www.goodreads.com/search?q=${search(title, author)}`,
  };
}

async function writeAtomic(file, text) {
  await mkdir(dirname(file), { recursive: true });
  const tmp = `${file}.tmp`;
  await writeFile(tmp, text, 'utf8');
  await rename(tmp, file);
}

function fail(msg) {
  console.error(`error: ${msg}`);
  process.exit(1);
}

try {
  const sheet = JSON.parse(await readFile(LIST_FILE, 'utf8'));
  if (!Array.isArray(sheet.owned) || !Array.isArray(sheet.tbr)) throw new Error('book-list.json needs "owned" and "tbr" arrays');
  if (!sheet.owned.length && !sheet.tbr.length) throw new Error('book-list.json is empty; refusing to empty the site');

  const csv = await readFile(CSV_FILE, 'utf8').catch(() => '');
  const gr = (csv ? parseCSV(csv) : []).map(r => {
    const { title, series } = splitSeries(r.Title || '');
    return {
      id: String(r['Book Id']), title, series, author: r.Author || '',
      short: shortTitle(title), surname: surname(r.Author),
      isbn10: digits(r.ISBN) || null, isbn13: digits(r.ISBN13) || null,
      myRating: num(r['My Rating']) || null,          // 0 means "not rated" on Goodreads
      avgRating: num(r['Average Rating']),
      year: num(r['Original Publication Year']) || num(r['Year Published']),
      pages: num(r['Number of Pages']),
      dateRead: grDate(r['Date Read']), dateAdded: grDate(r['Date Added']),
    };
  });
  const notes = JSON.parse(await readFile(NOTES_FILE, 'utf8').catch(() => '{}'));
  const covers = JSON.parse(await readFile(COVERS_FILE, 'utf8').catch(() => '{}'));

  // A book on both tabs is still waiting to be read: show it once, in Up Next.
  const tbrKeys = new Set(sheet.tbr.map(b => `${shortTitle(b.title)}|${surname(b.author)}`));
  const inTbr = b => tbrKeys.has(`${shortTitle(b.title)}|${surname(b.author)}`) ||
    (!b.author && [...tbrKeys].some(k => k.startsWith(shortTitle(b.title) + '|')));

  const entries = [
    ...sheet.tbr.map(e => ['upnext', e]),
    ...sheet.owned.filter(e => !inTbr(e)).map(e => ['library', e]),
  ];

  if (LOOKUP) {
    let looked = 0;
    for (const [, e] of entries) {
      const key = coverKey(e);
      if (key in covers) continue;
      try {
        let url = isbnCover(e, findGoodreads(e, gr));
        if (!url || !(await usable(url))) {
          url = await lookupCover(e);
          if (url && !(await usable(url))) url = '';
        }
        covers[key] = url || '';
        looked++;
      } catch (err) { console.warn(`cover lookup failed for "${e.title}": ${err.message}`); }
      await new Promise(r => setTimeout(r, 300));       // be polite to Open Library
    }
    const sorted = Object.fromEntries(Object.entries(covers).sort(([a], [b]) => a.localeCompare(b)));
    await writeAtomic(COVERS_FILE, JSON.stringify(sorted, null, 2) + '\n');
    console.log(`checked ${looked} cover(s)`);
  }

  let matched = 0;
  const books = entries.map(([list, e]) => {
    const g = findGoodreads(e, gr);
    if (g) matched++;
    if (g && process.env.DEBUG_MATCH && shortTitle(e.title) !== g.short) console.log(`  match: "${e.title}" / ${e.author} -> "${g.title}" / ${g.author}`);
    return toBook(e, list, g, notes, covers);
  });

  // Ids must be unique for the page; suffix any sheet-only collisions.
  const seen = new Map();
  for (const b of books) {
    const n = seen.get(b.id) || 0;
    seen.set(b.id, n + 1);
    if (n) b.id = `${b.id}-${n + 1}`;
  }

  const lib = books.filter(b => b.list === 'library'), up = books.filter(b => b.list === 'upnext');
  console.log(`${sheet.owned.length} owned and ${sheet.tbr.length} TBR on the sheet -> ` +
    `${lib.length} in the library, ${up.length} up next; ${matched} matched to Goodreads, ` +
    `${books.filter(b => b.blurb).length} with notes, ${books.filter(b => b.myRating).length} rated, ` +
    `${books.filter(b => b.cover).length} with a cover`);

  const next = JSON.stringify(books, null, 2) + '\n';
  const prev = await readFile(OUT_FILE, 'utf8').catch(() => null);
  if (prev === next) {
    console.log('books.json unchanged');
  } else {
    await writeAtomic(OUT_FILE, next);
    console.log(`wrote ${books.length} book(s) to ${OUT_FILE}`);
  }
} catch (err) {
  // Leave the existing books.json untouched so a bad input never empties the site.
  fail(err && err.message ? err.message : String(err));
}
