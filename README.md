# Website for Spex

This repository contains the source code for the Spex
[website](https://spex-lang.org).

## How it works

1. Edit markdown files in `src/`;
2. Do `make` to use `pandoc` to create HTML files in `dist/`;
3. Do `make publish` to push `dist/` to `gh-pages` branch, which deploys the
   website.
