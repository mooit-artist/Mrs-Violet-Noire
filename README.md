# Mrs. Violet Noire

Source for [mrsvioletnoire.com](https://mrsvioletnoire.com), the home page of Mrs. Violet Noire, curator of murder mysteries, psychological thrillers and domestic suspense.

Follow along on Goodreads: [Mrs Violet Noire](https://www.goodreads.com/user/show/8091033-mrs-violet-noire).

## Updating the library

1. On Goodreads, go to **My Books → Import and export → Export library** and download the CSV.
2. Replace `data/goodreads_library_export.csv` with it and push to `main`.
3. The **Build library** workflow rebuilds `data/books.json` and redeploys the site.

To add or change a book's note or Amazon link, edit `data/notes.json` (keyed by Goodreads Book Id). Ratings come from your Goodreads stars. Book links use the Amazon Associates tag `mrsvioletnoire-20`.

## Rights

© Mrs. Violet Noire. All rights reserved. The text, logos and images in this repository are not licensed for reuse.
