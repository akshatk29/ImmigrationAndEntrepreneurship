#!/usr/bin/env bash
# Build the thesis PDF locally.
# main.pdf stays in this folder; auxiliary files are moved to ./build/ (disposable).
# Requires a TeX distribution with latexmk (MiKTeX or TeX Live).
# Usage:  bash build.sh
set -e
cd "$(dirname "$0")"
latexmk -pdf -interaction=nonstopmode main.tex
mkdir -p build
for ext in aux bbl blg log out fls fdb_latexmk toc synctex.gz nav snm; do
  [ -f "main.$ext" ] && mv -f "main.$ext" build/
done
echo "Built: $(pwd)/main.pdf   (auxiliary files in build/)"
