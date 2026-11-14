# Mrs. Violet Noire

Source for [mrsvioletnoire.com](https://mrsvioletnoire.com), the home page of Mrs. Violet Noire, curator of murder mysteries, psychological thrillers and domestic suspense.

Follow along on Goodreads: [Mrs Violet Noire](https://www.goodreads.com/user/show/8091033-mrs-violet-noire).

## Updating the library

The **book-list** Google Sheet is the source of truth for the site:

- the **Owned** tab is the library ("On Her Shelves");
- **"Up Next"** is the books she owns but hasn't read: Owned rows with **Status** set to "Unread". Switch a book to "Read" when she finishes it and it moves to the library. The TBR tab adds format and date added for those books.
- **"To Be Read"** is the TBR books she doesn't own yet.

Edit the sheet, and the site follows. Once a day a scheduled sync reads both tabs, runs `scripts/import-book-list.mjs` and commits `data/book-list.json` if anything changed. The **Build library** workflow then rebuilds `data/books.json` and redeploys the site.

Only titles, authors, ISBNs, formats, TBR dates, read status and her own star ratings are published. Shelf locations, quantities, prices and the Notes column stay in the sheet.

To sync by hand, save each tab as a Sheets API `values.get` response and run:

```sh
node scripts/import-book-list.mjs owned.json tbr.json
node scripts/build-library.mjs
```

### Goodreads extras

The Goodreads export in `data/goodreads_library_export.csv` no longer decides which books appear. It adds her Goodreads star ratings, read dates and book links to matching books. To refresh it, export from **My Books → Import and export → Export library** on Goodreads and replace the file.

To add or change a book's note or Amazon link, edit `data/notes.json` (keyed by Goodreads Book Id). Amazon links are plain, untagged links for now. To turn affiliate links on, set the repository variable `AMAZON_TAG` (Settings → Secrets and variables → Actions → Variables) to the Associates tracking ID and re-run **Build library**. Every link gets the tag and the footer disclosure appears on its own. Covers come from Open Library, by ISBN when the sheet or Goodreads has one, otherwise by title search (cached in `data/covers.json`).

## Rights

© Mrs. Violet Noire. All rights reserved. The text, logos and images in this repository are not licensed for reuse.
