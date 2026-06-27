# Code

Four numbered scripts reproduce every table and figure in the thesis paper, plus all
upstream data processing. Run them in order. Tables are written directly into
`../paper/tables/` and figures into `../paper/figures/`; rebuild the PDF afterwards (see
"Build the paper").

Because the project mixes **Stata** (`.do`) and **Python** (`.py`), the analysis stage is
split by language — that is the only reason there are four scripts rather than three.

> **Run everything at once:** `bash ../master.sh` (from the repo root) runs steps 2→4 then builds
> the paper. See the root `README.md` for setup. The sections below describe each script so you can
> also run them individually.

---

## Scripts (run in this order)

| # | Script | Language | Stage | Produces |
|---|--------|----------|-------|----------|
| 1 | `1_download_data.py` | Python | Download | `data/0_raw_data/qcew_data/` (raw QCEW xlsx + `wage_data_combined.csv`) |
| 2 | `2_build_data.do` | Stata | Clean / build | the 6 analysis `.dta` files in `data/1_clean_data/` |
| 3 | `3_tables.do` | Stata | Analysis | 4 used tables (+1 unused) |
| 4 | `4_tables_and_figures.py` | Python | Analysis | 1 used table (+1 unused) and the used figures |

Scripts 3 and 4 both depend only on script 2, and can run in either order.

### Outputs by script

**`2_build_data.do`** → `data/1_clean_data/`:
`bds_analysis.dta`, `bds_pop_analysis.dta`, `wage_bds.dta`, `bds_age_analysis.dta`,
`survey_data.dta`, `sbo_new.dta`.

**`3_tables.do`** → `../paper/tables/`:
`immigration_stats.tex`, `sbo_stats.tex`, `bds_stats.tex` *(unused)*, `main_analysis.tex`,
`pop_analysis.tex`, `first_stage.tex`, `iv_sin.tex`, `bds_firm_age.tex`.

**`4_tables_and_figures.py`** → `../paper/tables/` and `../paper/figures/`:
`selection_gap.tex`, `tab_capital_educ.tex` *(unused)*,
`maps/immigration_shock_{1980..2010}.png`, `selection_gap.png`, `gap_simulation.png`.

*Unused* = produced by the code but commented out / not referenced in the compiled paper.

---

## Raw data: manual vs. API

**Fetched programmatically** (by `1_download_data.py`):

| Data | Source | Notes |
|---|---|---|
| QCEW wage data (county, high-level, 1990–2023) | [BLS open data](https://www.bls.gov/cew/additional-resources/open-data/home.htm) | No API key. The only fetched series used in the paper. |

**Manual downloads** — not produced by any script; place by hand before running step 2:

| File | Location | Source (download link) |
|---|---|---|
| `ImmigrationShock.dta` | `data/0_raw_data/` | Immigration instrument (Tarek Hassan) — [immigrationshock.com/immigration-shocks](https://www.immigrationshock.com/immigration-shocks) |
| `bds2023_st_cty.csv` | `data/0_raw_data/` | Census BDS, county — [census.gov BDS datasets](https://www.census.gov/data/datasets/time-series/econ/bds/bds-datasets.html) |
| `bds2023_st_cty_eac.csv` | `data/0_raw_data/` | Census BDS, county × firm-age cohort — [census.gov BDS datasets](https://www.census.gov/data/datasets/time-series/econ/bds/bds-datasets.html) |
| `pums.csv` | `data/0_raw_data/` | 2007 SBO PUMS — [census.gov 2007 SBO PUMS](https://www.census.gov/data/datasets/2007/econ/sbo/2007-sbo-pums.html) |
| `county_population.dta` | `data/0_raw_data/` | County population — [NBER intercensal county population, 1970–2014](https://www.nber.org/research/data/census-us-intercensal-county-population-data-1970-2014) (no build script) |

> **Note:** the `data/` directory is **not** included in this repository — neither the raw
> inputs above nor the processed `.dta` files are distributed on GitHub. Download each raw
> input from the public source listed above, place it in `data/0_raw_data/`, and run the
> pipeline (steps 1→2) to rebuild the clean datasets.


---

## Build the paper

After regenerating tables/figures:

```
bash ../paper/build.sh        # or:  cd ../paper && latexmk -pdf -jobname=ImmigrationAndEntrepreneurship main.tex
```

Produces `../paper/ImmigrationAndEntrepreneurship.pdf`. Requires a TeX distribution with `latexmk` and the `aer`
BibTeX style.

---

## Dependencies

**Stata** (install once via `ssc install`): `ivreghdfe`, `reghdfe`, `ftools`, `estout`,
and the `tab2` scheme (`schemepack`). Paths need no editing: the header matches a known
username, otherwise it falls back to the current directory — and `../master.sh` `cd`s to the
repo root before launching Stata, so a fresh clone just works. (Running a `.do` by hand?
`cd` to the repo root first, or add your own `if inlist("`c(username)'", ...)` branch.)

**Python** (`pip install -r requirements.txt`): `pandas`, `numpy`, `matplotlib`, `plotly`,
`kaleido` (PNG export of the maps), `linearmodels` (only the unused capital/education table),
`openpyxl` (reading QCEW Excel files). `ROOT` auto-resolves from each script's own location,
so no path editing is needed.

---

## Notes

- The `data/` directory is not distributed with this repo, so the processed/clean `.dta`
  files are not shipped: you must run step 1 (download) and step 2 (build) to regenerate them
  from raw inputs before steps 3–4 can produce the tables and figures. The heaviest step is
  rebuilding the survey data from `pums.csv` (~727 MB) in `2_build_data.do`.
- `4_tables_and_figures.py` runs each of its five blocks independently and reports — but does
  not stop on — a failure, so a missing optional dependency (e.g. `linearmodels`) does not
  block the other figures.
