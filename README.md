# README - Akshat's Thesis

*Created By: Akshat Kumar*
**LAST UPDATED: 26th Jun, 2026**

This repository contains code and data for Akshat's Honours Thesis at the Vancouver School of Economics, UBC.

## Layout

```
main_thesis/
├── code/      replication pipeline (4 numbered scripts) — see code/README.md
├── data/      0_raw_data/ (inputs), 1_clean_data/ (analysis .dta), _old/ (archive)
├── paper/     self-contained LaTeX project; tables/ + figures/ + main.pdf
└── master.sh  one-command reproduction (see below)
```

## Reproduce everything

From the repository root:

```
bash master.sh
```

This runs the build (`code/2_build_data.do`), the tables (`code/3_tables.do`), and the Python
tables/figures (`code/4_tables_and_figures.py`), then compiles `paper/main.pdf`. It uses the raw
data already in `data/`; run `DOWNLOAD=1 bash master.sh` to re-download the QCEW wage data from
BLS first (the only programmatically-fetched input).

**Before the first run:**
- Ensure the data dir exists and is populated
- Set your Stata executable — edit the `STATA=` line in `master.sh`, or run
  `STATA="/path/to/stata" bash master.sh` (default: `/c/Program Files/Stata18/StataSE-64.exe`).
- Install the Python dependencies: `pip install -r code/requirements.txt`.
- Install a TeX distribution with `latexmk` (for the paper build).
- Place the manually-downloaded raw inputs in `data/0_raw_data/` (listed in `code/README.md`).

Stata batch logs are written to `logs/`.
