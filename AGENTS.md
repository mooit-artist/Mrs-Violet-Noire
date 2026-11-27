# AI instructions: Mrs. Violet Noire

Read this before working in the repo. Keep it current; other AIs rely on it for status.

## What this is
- Source for https://mrsvioletnoire.com, a crime fiction book review site (murder mysteries, psychological thrillers, domestic suspense) for the curator "Mrs. Violet Noire".
- Part of Bryan's side ventures (Business project). Low effort, highest return first. FreshThreads is Tier 1 and goes live before this site gets new work.
- Static site: HTML in the repo root, data in `data/`, build scripts in `scripts/`, workflows in `.github/workflows/`.

## How content works
- The **book-list** Google Sheet is the source of truth (Owned and TBR tabs). A daily sync commits `data/book-list.json`; the **Build library** workflow rebuilds `data/books.json`; **Deploy site** publishes to Hostinger (`hostinger` branch) and Pages.
- Notes and Amazon links per book live in `data/notes.json`. Goodreads export in `data/` only adds ratings, dates and links.
- Published fields only: titles, authors, ISBNs, formats, TBR dates, read status, star ratings. Never publish shelf locations, quantities, prices or the Notes column.

## Monetization status
- Decision (Bryan, 2026-11-25): the site is too small for Amazon Associates now (it needs 3 qualifying sales within 180 days). Do not apply yet; revisit when traffic grows.
- Plan: Bookshop.org affiliate links first (10% commission, open to any website), newsletter next, Amazon Associates later, display ads only at roughly 50,000 sessions a month.
- The build supports Amazon links only (`AMAZON_TAG` repository variable, off). Bookshop links are not built yet; adding them is a small change to `scripts/build-library.mjs` and needs Bryan's approval first.
- Any affiliate link needs the footer disclosure. Any sponsored or gifted review needs FTC disclosure on the page.
- Status: no ads, no newsletter, no affiliate links live (as of 2026-11-25).

## Rules
- Do not change trackers, send messages, spend money or sign anything without Bryan's approval.
- Keep employer material out of this repo. Public sources and Bryan's own setup only.
- Do not commit secrets, tokens or the Associates ID outside the `AMAZON_TAG` variable.
- Open a pull request; do not commit straight to `main`.
- Reuse existing scripts and data files instead of adding new tooling.
