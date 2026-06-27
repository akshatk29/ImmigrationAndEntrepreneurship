#!/usr/bin/env bash
# Build the thesis PDF locally.
# ImmigrationAndEntrepreneurship.pdf stays in this folder; auxiliary files are
# moved to ./build/ (disposable).
# Requires a TeX distribution with latexmk (MiKTeX or TeX Live).
# Usage:  bash build.sh
set -e
cd "$(dirname "$0")"
jobname=ImmigrationAndEntrepreneurship
latexmk -pdf -interaction=nonstopmode -jobname="$jobname" main.tex
mkdir -p build
for ext in aux bbl blg log out fls fdb_latexmk toc synctex.gz nav snm; do
  [ -f "$jobname.$ext" ] && mv -f "$jobname.$ext" build/
done
echo "Built: $(pwd)/$jobname.pdf   (auxiliary files in build/)"
