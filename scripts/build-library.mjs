#!/usr/bin/env node
/**
 * build-library.mjs — turn the Goodreads export into data/books.json
 *
 * Runs in GitHub Actions whenever the export or notes change
 * (see .github/workflows/build-library.yml). Node 20+, no dependencies,
 * no network access.
 *
 * Inputs:
 *   data/goodreads_library_export.csv  Goodreads > My Books > Import and export > Export library
 *   data/notes.json                    Mrs. Noire's blurbs and hand-picked Amazon links,
 *                                      keyed by Goodreads Book Id (optional per book)
 *
 * Output:
 *   data/books.json                    what the home page renders
 *
 * Env:
 *   AMAZON_TAG   Amazon Associates tracking ID (default "mrsvioletnoire-20")
 *
 * Behaviour:
 *   - Only books on the "read" shelf are published.
 *   - A malformed CSV exits non-zero and leaves the existing books.json alone.
 */

import { readFile, writeFile, rename, mkdir } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const CSV_FILE = resolve(ROOT, 'data', 'goodreads_library_export.csv');
const NOTES_FILE = resolve(ROOT, 'data', 'notes.json');
const OUT_FILE = resolve(ROOT, 'data', 'books.json');
const TAG = (process.env.AMAZON_TAG || 'mrsvioletnoire-20').trim();

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
  const [header, ...body] = rows;
  return body.map(r => Object.fromEntries(header.map((h, i) => [h.trim(), (r[i] ?? '').trim()])));
}

// Goodreads wraps ISBNs as ="0123456789" so spreadsheets keep leading zeros.
const isbn = s => String(s || '').replace(/[^0-9Xx]/g, '').toUpperCase();
const num = s => (s === '' || s == null || Number.isNaN(Number(s)) ? null : Number(s));
const date = s => (/^\d{4}\/\d{2}\/\d{2}$/.test(s || '') ? s.replace(/\//g, '-') : null);

function splitSeries(title) {
  const m = /^(.*?)\s*\(([^()]*#[^()]*)\)\s*$/.exec(title);
  return m ? { title: m[1].trim(), series: m[2].trim() } : { title: title.trim(), series: null };
}

function amazonUrl(note, isbn10, title, author) {
  if (note?.amazon && /^https:\/\/www\.amazon\.com\//.test(note.amazon)) return note.amazon;
  // For print books the ISBN-10 is also the Amazon ASIN.
  if (isbn10.length === 10) return `https://www.amazon.com/dp/${isbn10}?tag=${encodeURIComponent(TAG)}`;
  const q = encodeURIComponent(`${title} ${author}`).replace(/%20/g, '+');
  return `https://www.amazon.com/s?k=${q}&i=stripbooks&tag=${encodeURIComponent(TAG)}`;
}

function toBook(row, notes) {
  const id = String(row['Book Id']);
  const note = notes[id] || null;
  const { title, series } = splitSeries(row.Title || '');
  const author = row.Author || '';
  const isbn10 = isbn(row.ISBN);
  const isbn13 = isbn(row.ISBN13);
  const coverIsbn = isbn13 || isbn10;
  return {
    id,
    title,
    series,
    author,
    myRating: num(row['My Rating']) || null,       // 0 means "not rated" on Goodreads
    avgRating: num(row['Average Rating']),
    year: num(row['Original Publication Year']) || num(row['Year Published']),
    pages: num(row['Number of Pages']),
    dateRead: date(row['Date Read']),
    dateAdded: date(row['Date Added']),
    blurb: note?.blurb || null,
    cover: coverIsbn ? `https://covers.openlibrary.org/b/isbn/${coverIsbn}-M.jpg?default=false` : null,
    amazon: amazonUrl(note, isbn10, title, author),
    goodreads: `https://www.goodreads.com/book/show/${encodeURIComponent(id)}`,
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
  const rows = parseCSV(await readFile(CSV_FILE, 'utf8'));
  for (const col of ['Book Id', 'Title', 'Author', 'Exclusive Shelf']) {
    if (rows.length && !(col in rows[0])) throw new Error(`CSV is missing the "${col}" column. Is this a Goodreads export?`);
  }
  const notes = JSON.parse(await readFile(NOTES_FILE, 'utf8').catch(() => '{}'));

  const books = rows
    .filter(r => r['Exclusive Shelf'] === 'read')
    .map(r => toBook(r, notes))
    .sort((a, b) =>
      (b.dateRead || b.dateAdded || '').localeCompare(a.dateRead || a.dateAdded || '') ||
      Number(b.id) - Number(a.id));

  console.log(`${rows.length} row(s) in export, ${books.length} on the read shelf, ` +
    `${books.filter(b => b.blurb).length} with notes, ${books.filter(b => b.myRating).length} rated`);

  const next = JSON.stringify(books, null, 2) + '\n';
  const prev = await readFile(OUT_FILE, 'utf8').catch(() => null);
  if (prev === next) {
    console.log('books.json unchanged');
  } else {
    await writeAtomic(OUT_FILE, next);
    console.log(`wrote ${books.length} book(s) to ${OUT_FILE}`);
  }
} catch (err) {
  // Leave the existing books.json untouched so a bad export never empties the site.
  fail(err && err.message ? err.message : String(err));
}
