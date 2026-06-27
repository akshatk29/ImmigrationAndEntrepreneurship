#!/usr/bin/env bash
# =============================================================================
# master.sh - reproduce the thesis end to end, from raw data to paper/main.pdf
# =============================================================================
# Runs the replication pipeline:
#   [2] code/2_build_data.do        (Stata)  -> data/1_clean_data/*.dta
#   [3] code/3_tables.do            (Stata)  -> paper/tables/*.tex
#   [4] code/4_tables_and_figures.py (Python) -> paper/tables, paper/figures
#       paper/build.sh              (latexmk) -> paper/main.pdf
#
# Step [1] code/1_download_data.py re-downloads ~900 MB of QCEW data from BLS and
# is OFF by default (the raw data ships with the package). Enable with DOWNLOAD=1.
#
# Usage:
#   bash master.sh                 # build from the raw data already in data/
#   DOWNLOAD=1 bash master.sh      # also re-download + reprocess QCEW first
#   STATA="/path/to/stata" bash master.sh   # override the Stata executable
#
# Requirements: Stata (CLI), Python deps (pip install -r code/requirements.txt),
# and a TeX distribution with latexmk (same as paper/build.sh).
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")"

# --- Configuration ----------------------------------------------------------
# Path to your Stata executable. Replicators: edit this line or `export STATA=`.
#   Windows : /c/Program Files/Stata18/StataSE-64.exe   (or StataMP-64 / StataBE-64)
#   macOS   : /Applications/Stata/StataSE.app/Contents/MacOS/stata-se
#   Linux   : stata-se
STATA="${STATA:-/c/Program Files/Stata18/StataSE-64.exe}"

# Run a .do file in batch mode. Stata's -e returns 0 even on error, so we grep
# the batch log for an r(###); error code and stop the pipeline if one appears.
run_stata () {
	local dofile="$1"
	local log; log="$(basename "${dofile%.do}").log"
	echo ">>> stata -e do $dofile"
	"$STATA" -e do "$dofile"
	if grep -qE '^r\([0-9]+\);' "$log" 2>/dev/null; then
		echo "ERROR: Stata reported an error in $dofile (see ./$log)" >&2
		exit 1
	fi
	mkdir -p logs && mv -f "$log" "logs/$log"
}

# --- [1/4] Download (optional) ----------------------------------------------
if [ "${DOWNLOAD:-0}" = "1" ]; then
	echo "### [1/4] Downloading + processing QCEW wage data ..."
	python code/1_download_data.py
else
	echo "### [1/4] Skipping download (set DOWNLOAD=1 to enable); using existing raw data."
fi

# --- [2/4] Build analysis datasets (Stata) ----------------------------------
echo "### [2/4] Building analysis datasets -> data/1_clean_data/ ..."
run_stata code/2_build_data.do

# --- [3/4] Tables (Stata) ---------------------------------------------------
echo "### [3/4] Generating tables -> paper/tables/ ..."
run_stata code/3_tables.do

# --- [4/4] Tables + figures (Python) ----------------------------------------
echo "### [4/4] Generating Python tables + figures -> paper/{tables,figures}/ ..."
python code/4_tables_and_figures.py

# --- Build the paper --------------------------------------------------------
echo "### Building paper -> paper/main.pdf ..."
bash paper/build.sh

echo "### Done. Output: paper/main.pdf   (Stata batch logs in logs/)"
