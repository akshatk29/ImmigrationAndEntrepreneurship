# Tables & Figures Inventory

Full list of every table and figure source in the project, with a one-line description.
**Status** = whether it currently appears in the compiled PDF (`✅ Used` / `❌ Unused`).

> Inventory generated 2026-06-26. All tables/figures are pulled into the PDF via `sections/tables_figures.tex` (appendix "Tables and Figures").

---

## Tables (`tables/`)

| # | File | Label | Title | Status | One-line description |
|---|------|-------|-------|--------|----------------------|
| 1 | `immigration_stats.tex` | `tab:immigration` | Immigration Data | ✅ Used | Summary stats (N, mean, min, max, SD) for the immigration instrument and 5-year immigration flows at the county level. |
| 2 | `sbo_stats.tex` | `tab:sbo` | Survey Data by Ownership Type | ✅ Used | Weighted means/SDs of firm characteristics (age, employment, payroll, receipts, family/home-based, etc.) split by All / American / Immigrant / Mixed ownership, 2007 SBO. |
| 3 | `selection_gap.tex` | `tab:selection_gap` | Selection Gap From 2007 SBO Data | ✅ Used | New- vs young-firm size in the top capital bucket for natives vs immigrants, and the implied selection gap (1.74 difference). |
| 4 | `first_stage.tex` | `tab:firststage` | IV First Stage | ✅ Used | First-stage regressions of non-European migration on the immigration-shock instrument across State/County and State-Time FE specs. |
| 5 | `main_analysis.tex` | `tab:main` | Immigration IV: Business Dynamics | ✅ Used | Headline IV estimates of log immigration on wages, firm size, entry rate, and exit rate. |
| 6 | `iv_sin.tex` | `tab:sin_iv` | Inverse Hyperbolic Sine of Immigration IV: Business Dynamics | ✅ Used | Robustness check re-running the main IV using the IHS transform of immigration instead of logs. |
| 7 | `pop_analysis.tex` | `tab:pop` | Immigration IV: Business Dynamics with Population Change | ✅ Used | Main IV specification with a population control added to the four outcomes. |
| 8 | `bds_firm_age.tex` | `tab:bdsage` | Immigration IV: Heterogeneous Effects by Firm Age | ✅ Used | IV effects on exit rate (Panel A) and firm size (Panel B), broken out by New/Young/Medium/Old firm-age groups. |
| 9 | `bds_stats.tex` | `tab:bds` | Business Dynamics Data | ❌ Unused | Summary stats for county-year BDS variables (firm/establishment counts, births, exits, job creation/destruction), 1978–2010. *(commented out in `tables_figures.tex:4`)* |
| 10 | `tab_capital_educ.tex` | `tab:capital_educ` | Startup Capital and Owner Education | ❌ Unused | Weighted OLS of startup capital on owner education across FE specs, by All / Native / Immigrant owners. *(commented out in `tables_figures.tex:37`)* |

---

## Figures (`figures/`)

| # | File(s) | Label | Title | Status | One-line description |
|---|---------|-------|-------|--------|----------------------|
| 1 | `maps.tex` + `maps/immigration_shock_{1980,1985,1990,1995,2000,2005,2010}.png` | `fig:immigration_map` | Immigration Shocks (Instruments) | ✅ Used | Seven-panel grid of U.S. county choropleth maps showing the immigration-shock instrument for each 5-year period from 1975 to 2010. |
| 2 | `gap_simulation.png` | `fig:gap_simulation` | Selection Gap Using Simulated Data | ✅ Used | Line plot of the selection gap rising with capital class for two simulated groups. |
| 3 | `selection_gap.png` | `fig:gap_data` | Selection Gap using 2007 SBO Data | ✅ Used | Line plot of the selection gap (young-minus-new firm size) by capital class, natives vs immigrants, 2007 SBO. |
| 4 | `exit_rate_plot.png` | — | *(no caption — not referenced)* | ❌ Unused | Coefficient plot with 95% CIs of immigration's effect on exit rate by firm-age group (Young / Medium / 11+ yrs). |

---

### Summary

- **Tables:** 10 total — 8 used, 2 unused (`bds_stats`, `tab_capital_educ`, both commented out).
- **Figures:** 4 total — 3 used, 1 unused (`exit_rate_plot.png`, never referenced by any `\includegraphics`).
- The 7 individual map PNGs are all consumed by the single `maps.tex` figure.
