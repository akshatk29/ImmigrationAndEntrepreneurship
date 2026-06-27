# Immigration And Entrepreneurship Replication Material

*Created By: Akshat Kumar*

**LAST UPDATED: 27th Jun, 2026**

This repository contains the code and paper for Akshat's BA Honours Thesis at the Vancouver School of Economics, UBC titled *"Importing Talent? Evidence from Immigrant-Owned Businesses in the U.S."*.

## Layout

```
main_thesis/
├── code/      replication pipeline (4 numbered scripts) — see code/README.md
├── data/      0_raw_data/ (inputs), 1_clean_data/ (analysis .dta)  — NOT in this repo, see "Data" below
├── paper/     self-contained LaTeX project; tables/ + figures/ + ImmigrationAndEntrepreneurship.pdf
└── master.sh  one-command reproduction (see below)
```

## Data

**The `data/` directory is not distributed with this repository.** None of the raw
inputs or the processed `.dta` files are included on GitHub. Replicators must obtain
the raw inputs themselves from their original public sources and rebuild the analysis
datasets from scratch by running the pipeline (steps 1→2 below).

- **QCEW wage data** is fetched programmatically — run `DOWNLOAD=1 bash master.sh` (or
  `python code/1_download_data.py`).
- **All other raw inputs** are manual downloads from public sources (Census BDS, 2007 SBO
  PUMS, NBER county population, and the Hassan immigration instrument). Each file, its
  expected location under `data/0_raw_data/`, and its source is listed in `code/README.md`.

Create the `data/` tree and place the manual downloads in `data/0_raw_data/` before the
first run.

## Reproduce everything

From the repository root:

```
bash master.sh
```

This runs the build (`code/2_build_data.do`), the tables (`code/3_tables.do`), and the Python
tables/figures (`code/4_tables_and_figures.py`), then compiles `paper/ImmigrationAndEntrepreneurship.pdf`.
Because the data is not shipped (see **Data** above), a fresh clone must first populate
`data/0_raw_data/` and let the pipeline rebuild the clean `.dta` files — run
`DOWNLOAD=1 bash master.sh` to also fetch the QCEW wage data from BLS.

**Before the first run:**
- Obtain the raw inputs (see **Data** above) and place the manual downloads in
  `data/0_raw_data/` (each file and source is listed in `code/README.md`).
- Set your Stata executable — edit the `STATA=` line in `master.sh`, or run
  `STATA="/path/to/stata" bash master.sh` (default: `/c/Program Files/Stata18/StataSE-64.exe`).
- Install the Python dependencies: `pip install -r code/requirements.txt`.
- Install a TeX distribution with `latexmk` (for the paper build).

Stata batch logs are written to `logs/`.
