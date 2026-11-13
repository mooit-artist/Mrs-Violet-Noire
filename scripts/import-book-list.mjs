#!/usr/bin/env node
/**
 * import-book-list.mjs — turn the book-list Google Sheet into data/book-list.json
 *
 * The book-list sheet is the source of truth for the site:
 *   Owned tab -> "The Library"
 *   TBR tab   -> "Up Next"
 *
 * Usage:
 *   node scripts/import-book-list.mjs <owned.json> <tbr.json>
 *
 * Each input is a Sheets API `values.get` response ({ "values": [[...], ...] })
 * for that tab, header row first. Columns are found by header name, so they can
 * be reordered in the sheet.
 *
 * Only public fields are written: title, author, ISBN, format, date added,
 * read status and Mrs. Noire's own star rating. Shelf locations, quantities, prices and the
 * Notes column (where each copy came from) stay private in the sheet.
 *
 * Node 20+, no dependencies, no network access. A missing column or an empty
 * tab exits non-zero and leaves the existing data/book-list.json alone.
 */

import { readFile, writeFile, rename } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const OUT_FILE = resolve(ROOT, 'data', 'book-list.json');

function fail(msg) {
  console.error(`error: ${msg}`);
  process.exit(1);
}

const clean = s => String(s ?? '').replace(/\s+/g, ' ').trim();
const isbn = s => {
  const d = String(s ?? '').replace(/[^0-9Xx]/g, '').toUpperCase();
  return d.length === 10 || d.length === 13 ? d : null;
};
// "*****", "5", "4.5" -> number of stars; anything else -> null
const stars = s => {
  s = clean(s);
  if (/^\*{1,5}$/.test(s)) return s.length;
  if (/^★{1,5}/.test(s)) return (s.match(/★/g) || []).length;
  const n = Number(s);
  return Number.isFinite(n) && n >= 1 && n <= 5 ? n : null;
};
const isoDate = s => {
  s = clean(s);
  if (!s) return null;
  const d = new Date(`${s} 12:00 UTC`);
  return Number.isNaN(d.getTime()) ? null : d.toISOString().slice(0, 10);
};

async function readTab(file, label, required) {
  const raw = JSON.parse(await readFile(file, 'utf8'));
  const [header = [], ...rows] = raw.values || [];
  const col = Object.fromEntries(header.map((h, i) => [clean(h).toLowerCase(), i]));
  const find = name => Object.keys(col).find(k => k === name || k.startsWith(name + ' '));
  for (const name of required) {
    if (find(name) === undefined) fail(`${label} tab is missing the "${name}" column`);
  }
  const get = (row, name) => {
    const k = find(name);
    return k === undefined ? '' : clean(row[col[k]]);
  };
  const out = rows.map(r => ({ get: name => get(r, name) })).filter(r => r.get('title'));
  if (!out.length) fail(`${label} tab has no books; refusing to empty the site`);
  return out;
}

const [ownedFile, tbrFile] = process.argv.slice(2);
if (!ownedFile || !tbrFile) fail('usage: import-book-list.mjs <owned.json> <tbr.json>');

try {
  const owned = (await readTab(ownedFile, 'Owned', ['title', 'author'])).map(r => ({
    title: r.get('title'),
    author: r.get('author') || null,
    isbn: isbn(r.get('isbn')),
    rating: stars(r.get('rating')),
    // Status column: "Read" / "Unread". Missing or blank = not set.
    status: /^unread$/i.test(r.get('status')) ? 'unread' : /^read$/i.test(r.get('status')) ? 'read' : null,
  }));
  const tbr = (await readTab(tbrFile, 'TBR', ['title', 'author'])).map(r => ({
    title: r.get('title'),
    author: r.get('author') || null,
    isbn: isbn(r.get('isbn')),
    format: r.get('format') || null,
    dateAdded: isoDate(r.get('date added')),
  }));

  const next = JSON.stringify({ owned, tbr }, null, 2) + '\n';
  const prev = await readFile(OUT_FILE, 'utf8').catch(() => null);
  if (prev === next) {
    console.log(`book-list.json unchanged (${owned.length} owned, ${tbr.length} TBR)`);
  } else {
    await writeFile(`${OUT_FILE}.tmp`, next, 'utf8');
    await rename(`${OUT_FILE}.tmp`, OUT_FILE);
    console.log(`wrote ${owned.length} owned and ${tbr.length} TBR book(s) to ${OUT_FILE}`);
  }
} catch (err) {
  fail(err && err.message ? err.message : String(err));
}
