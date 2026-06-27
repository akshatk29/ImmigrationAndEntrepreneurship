"""
Main Thesis - Tables & Figures (Python)

Produces the Python-generated tables and figures:
    1. Selection gap table    -> paper/tables/selection_gap.tex
    2. Capital/education table -> paper/tables/tab_capital_educ.tex   (UNUSED in paper)
    3. Immigration shock maps  -> paper/figures/maps/immigration_shock_{1980..2010}.png
    4. Selection gap plot      -> paper/figures/selection_gap.png
    5. Simulated selection gap -> paper/figures/gap_simulation.png

Inputs:
    - data/1_clean_data/sbo_new.dta         (from 2_build_data.do)   [sections 1, 2, 4]
    - data/0_raw_data/ImmigrationShock.dta                           [section 3]
    (section 5 is a self-contained simulation with no data input)

Dependencies: pandas, numpy, matplotlib, plotly, kaleido (PNG export of maps),
linearmodels (section 2 only). See code/requirements.txt.

Last Updated: 26th June, 2026
Created by: Akshat Kumar
"""
import os

import matplotlib
matplotlib.use("Agg")   # headless / batch rendering
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# Project root = the parent of this script's directory (code/..). Auto-resolves so
# the package runs from any clone location without editing paths.
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

SBO_FILE    = os.path.join(ROOT, "data", "1_clean_data", "sbo_new.dta")
IMMIG_FILE  = os.path.join(ROOT, "data", "0_raw_data", "ImmigrationShock.dta")
TABLES_DIR  = os.path.join(ROOT, "paper", "tables")
FIGURES_DIR = os.path.join(ROOT, "paper", "figures")
MAPS_DIR    = os.path.join(FIGURES_DIR, "maps")

# Selection-gap age parameters (shared by sections 1 and 4)
NEW_AGE   = 1   # firms aged 0-NEW_AGE are "new"
YOUNG_AGE = 3   # firms aged NEW_AGE+1-YOUNG_AGE are "young"


def wmean(df, val_col="employment_noisy", wgt_col="tabwgt"):
    """Weighted mean of `val_col` using `wgt_col` (NaN if total weight is 0)."""
    w = df[wgt_col]
    v = df[val_col]
    if w.sum() == 0:
        return np.nan
    return np.average(v, weights=w)


# ===========================================================================
# 1. Selection gap table  ->  paper/tables/selection_gap.tex
# ===========================================================================
#
# For each nativity group, compute the weighted mean of employment_noisy for new
# vs. young firms (top startup-capital class), then report the gap (young - new)
# and the Native-Immigrant difference (the 1.74 selection gap).

def selgap_load_groups(new_age, young_age, capital_classes):
    cols = [
        "employment_noisy", "tabwgt", "firm_age",
        "fully_american", "fully_immigrant", "numowners", "educ1", "scamount",
    ]
    df = pd.read_stata(SBO_FILE, convert_categoricals=False, columns=cols)

    df = df.dropna(subset=["employment_noisy", "tabwgt"])

    # Capital-class filter (scamount is object/string dtype)
    classes_str = [str(c) for c in capital_classes]
    df = df[df["scamount"].isin(classes_str)]
    print(f"\nAfter capital-class filter (scamount in {classes_str}): {len(df):,} obs")

    native    = df["fully_american"] == 1
    immigrant = df["fully_immigrant"] == 1

    groups = {
        "Native":    df[native],
        "Immigrant": df[immigrant],
    }

    result = {}
    for name, gdf in groups.items():
        new_df   = gdf[gdf["firm_age"].between(0, new_age)]
        young_df = gdf[gdf["firm_age"].between(new_age + 1, young_age)]
        result[name] = {"new": new_df, "young": young_df}

    return result


def selgap_write_tex(results, new_age, young_age, output_dir):
    """Write the Selection Gap table (tab:selection_gap), matching the paper layout."""
    os.makedirs(output_dir, exist_ok=True)
    path = os.path.join(output_dir, "selection_gap.tex")

    nat = results["Native"]       # (mean_new, mean_young, gap)
    imm = results["Immigrant"]
    diff_new   = nat[0] - imm[0]
    diff_young = nat[1] - imm[1]
    diff_gap   = nat[2] - imm[2]

    lines = [
        r"\begin{table}",
        r"    \centering",
        r"\begin{tabular}{lccc}",
        r"\multicolumn{4}{c}{\large \textbf{Firms in Top Capital Bucket}} \\",
        r"\toprule \toprule",
        r" & \multicolumn{2}{c}{\textbf{Firm Size}} & \textbf{Selection Gap} \\",
        r"\cmidrule(lr){2-3}  & New Firms & Young Firms &  \\",
        r"\midrule ",
        rf"Native & {nat[0]:.2f} & {nat[1]:.2f} & {nat[2]:.2f} \\",
        rf"Immigrant & {imm[0]:.2f} & {imm[1]:.2f} & {imm[2]:.2f} \\",
        r"\midrule",
        rf"Difference & {diff_new:.2f} & {diff_young:.2f} & {diff_gap:.2f} \\",
        r"\bottomrule \bottomrule",
        rf"\multicolumn{{4}}{{l}}{{\small\textit{{Note:}} New firms are defined as those of ages 0 and {new_age} while}} \\",
        rf"\multicolumn{{4}}{{l}}{{\small young firms are of ages {new_age + 1} and {young_age} years.}} ",
        r"\end{tabular}",
        r" \caption{Selection Gap From 2007 SBO Data}",
        r"    \label{tab:selection_gap}\end{table}",
    ]

    with open(path, "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"LaTeX table written to {path}")


def selgap_table(new_age, young_age, capital_classes, output_dir):
    print(f"New firms  : age in [0, {new_age}]")
    print(f"Young firms: age in [{new_age + 1}, {young_age}]")
    print(f"Capital classes: scamount in {[str(c) for c in capital_classes]}")

    groups = selgap_load_groups(new_age, young_age, capital_classes)

    col_w = 28
    header = (
        f"\n{'Group':<{col_w}}  {'New (mean emp)':>16}  "
        f"{'Young (mean emp)':>16}  {'Diff (young-new)':>16}  "
        f"{'n_new':>7}  {'n_young':>7}"
    )
    print(header)
    print("-" * len(header.strip()))

    tex_results = {}
    for name, cohorts in groups.items():
        new_df   = cohorts["new"]
        young_df = cohorts["young"]

        mean_new   = wmean(new_df)
        mean_young = wmean(young_df)
        diff = (
            mean_young - mean_new
            if not (np.isnan(mean_new) or np.isnan(mean_young))
            else np.nan
        )

        print(
            f"{name:<{col_w}}  "
            f"{mean_new:>16.3f}  "
            f"{mean_young:>16.3f}  "
            f"{diff:>+16.3f}  "
            f"{len(new_df):>7,}  "
            f"{len(young_df):>7,}"
        )
        tex_results[name] = (mean_new, mean_young, diff)

    selgap_write_tex(tex_results, new_age, young_age, output_dir)


# ===========================================================================
# 2. Capital / education table  ->  paper/tables/tab_capital_educ.tex (UNUSED)
# ===========================================================================
#
# Regression of startup capital (scamount) on owner education (educ1) under 4 FE
# specs, for All / Native / Immigrant owners. Survey-weighted WLS, SEs clustered
# at state level. scamount values 0, 9, and "A" dropped.

try:
    from linearmodels import AbsorbingLS
except ImportError:
    AbsorbingLS = None

CAPEDUC_INVALID_SCAMOUNT = {0, 9}   # "A" -> NaN via pd.to_numeric (coerce)
CAPEDUC_SPECS = [
    (False, False),
    (True,  False),
    (False, True),
    (True,  True),
]
CAPEDUC_SPEC_LABELS = ["No FE", "State FE", "Sector FE", "Both FE"]


def capeduc_load_data():
    cols = [
        "scamount", "educ1", "tabwgt",
        "fully_american", "fully_immigrant",
        "state", "sector",
    ]
    df = pd.read_stata(SBO_FILE, convert_categoricals=False, columns=cols)
    df["scamount"] = pd.to_numeric(df["scamount"], errors="coerce")
    df["educ1"]    = pd.to_numeric(df["educ1"],    errors="coerce")
    df = df.dropna(subset=["scamount", "educ1", "tabwgt", "state", "sector"])
    df = df[df["tabwgt"] > 0]
    df = df[~df["scamount"].isin(CAPEDUC_INVALID_SCAMOUNT)]
    df["state"]  = df["state"].astype(str)
    df["sector"] = df["sector"].astype(str)
    return df.reset_index(drop=True)


def capeduc_run_spec(df, fe_state=False, fe_sector=False):
    y        = df["scamount"]
    X        = df[["educ1"]]
    weights  = df["tabwgt"]
    clusters = df["state"]

    absorb_cols = {}
    if fe_state:
        absorb_cols["state"]  = pd.Categorical(df["state"])
    if fe_sector:
        absorb_cols["sector"] = pd.Categorical(df["sector"])

    absorb = pd.DataFrame(absorb_cols) if absorb_cols else None

    mod = AbsorbingLS(y, X, absorb=absorb, weights=weights)
    res = mod.fit(cov_type="clustered", clusters=clusters)
    return res


def stars(pval):
    if pval < 0.01: return "***"
    if pval < 0.05: return "**"
    if pval < 0.10: return "*"
    return ""


def stars_tex(pval):
    if pval < 0.01: return "^{***}"
    if pval < 0.05: return "^{**}"
    if pval < 0.10: return "^{*}"
    return ""


def capeduc_write_latex_table(panel_results, path):
    """Write a booktabs-style LaTeX table ready for \\input{}."""
    NC = len(CAPEDUC_SPECS)  # number of spec columns

    lines = []
    a = lines.append

    a(r"% -------------------------------------------------------")
    a(r"% Required packages: booktabs, threeparttable, caption")
    a(r"% -------------------------------------------------------")
    a(r"\begin{table}[htbp]")
    a(r"\centering")
    a(r"\caption{Startup Capital and Owner Education}")
    a(r"\label{tab:capital_educ}")
    a(r"\begin{threeparttable}")
    a(r"\begin{tabular}{l" + "c" * NC + r"}")
    a(r"\toprule")

    spec_header = " & " + " & ".join(f"({i+1})" for i in range(NC)) + r" \\"
    a(spec_header)
    label_header = " & " + " & ".join(lbl for lbl in CAPEDUC_SPEC_LABELS) + r" \\"
    a(label_header)
    a(r"\midrule")

    for p_idx, (panel_name, results, wtd_n) in enumerate(panel_results):
        a(r"\multicolumn{" + str(NC + 1) + r"}{l}{\textit{" + panel_name + r"}} \\[3pt]")

        coef_cells = []
        se_cells   = []
        r2_cells   = []

        for res in results:
            c  = res.params["educ1"]
            p  = res.pvalues["educ1"]
            se = res.std_errors["educ1"]
            r2 = res.rsquared

            coef_cells.append(f"${c:.4f}{stars_tex(p)}$")
            se_cells.append(f"$({se:.4f})$")
            r2_cells.append(f"{r2:.4f}")

        n_cells = [f"{wtd_n:,}"] * NC

        a(r"\quad educ1 & " + " & ".join(coef_cells) + r" \\")
        a(r" & " + " & ".join(se_cells) + r" \\")
        a(r"\midrule")
        a(r"\quad Observations & " + " & ".join(n_cells) + r" \\")
        a(r"\quad $R^{2}$ & " + " & ".join(r2_cells) + r" \\")

        if p_idx < len(panel_results) - 1:
            a(r"\midrule")

    a(r"\midrule")

    state_vals  = ["Yes" if fe_s   else "No" for fe_s, fe_sec in CAPEDUC_SPECS]
    sector_vals = ["Yes" if fe_sec else "No" for fe_s, fe_sec in CAPEDUC_SPECS]
    a(r"State FE & "  + " & ".join(state_vals)  + r" \\")
    a(r"Sector FE & " + " & ".join(sector_vals) + r" \\")

    a(r"\bottomrule")
    a(r"\end{tabular}")
    a(r"\begin{tablenotes}")
    a(r"\footnotesize")
    a(r"\item \textit{Notes:} Weighted OLS using survey weights (\texttt{tabwgt}).")
    a(r"Standard errors in parentheses, clustered at the state level.")
    a(r"\texttt{scamount} values 0, 9, and `A' excluded.")
    a(r"$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.")
    a(r"\end{tablenotes}")
    a(r"\end{threeparttable}")
    a(r"\end{table}")

    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")

    print(f"LaTeX table written to: {path}")


def capeduc_table(output_tex):
    if AbsorbingLS is None:
        print("  [skip] linearmodels not installed; skipping tab_capital_educ.tex")
        return

    print("Loading and cleaning data...", flush=True)
    df = capeduc_load_data()
    print(f"  n = {len(df):,} after cleaning\n", flush=True)

    subsets = [
        ("Panel A: All Owners",       df),
        ("Panel B: Native Owners",    df[df["fully_american"]  == 1].reset_index(drop=True)),
        ("Panel C: Immigrant Owners", df[df["fully_immigrant"] == 1].reset_index(drop=True)),
    ]

    panel_results = []
    for panel_name, sub in subsets:
        print(f"Running {panel_name}  (n={len(sub):,})", flush=True)
        results = []
        for i, (fe_s, fe_sec) in enumerate(CAPEDUC_SPECS):
            res = capeduc_run_spec(sub, fe_state=fe_s, fe_sector=fe_sec)
            c, p, se = res.params["educ1"], res.pvalues["educ1"], res.std_errors["educ1"]
            print(f"  ({i+1}) {CAPEDUC_SPEC_LABELS[i]:<12}: coef={c:.4f}  se={se:.4f}  p={p:.3f}",
                  flush=True)
            results.append(res)
        wtd_n = int(round(sub["tabwgt"].sum()))
        panel_results.append((panel_name, results, wtd_n))
        print()

    os.makedirs(os.path.dirname(output_tex), exist_ok=True)
    capeduc_write_latex_table(panel_results, output_tex)


# ===========================================================================
# 3. Immigration shock maps  ->  paper/figures/maps/immigration_shock_{year}.png
# ===========================================================================

def clean_fips(fips):
    """Convert a numeric CountyCode to a zero-padded 5-character FIPS string."""
    fips_str = str(int(fips))

    # Remove trailing digit
    fips_str = fips_str[:-1]

    # Add leading zero if length is 4
    if len(fips_str) == 4:
        fips_str = "0" + fips_str

    assert len(fips_str) == 5, f"FIPS code {fips_str} is not 5 characters long."
    return fips_str


def map_immigration_quantiles(dta_path, year, num_quantiles=200,
                              variable="ImmigrationShock", output_dir=None):
    """Choropleth of the immigration instrument by county for a given year, binned
    into quantiles. Saves a PNG (requires the `kaleido` package)."""
    import plotly.express as px

    df = pd.read_stata(dta_path)

    # Keep the requested year
    df = df[df["Year"] == year]

    # Clean FIPS to string
    df["FIPS"] = df["CountyCode"].apply(clean_fips)

    # Create quantile bins
    df["Quantile"] = pd.qcut(df[variable], num_quantiles, labels=False)

    fig = px.choropleth(
        df,
        geojson="https://raw.githubusercontent.com/plotly/datasets/master/geojson-counties-fips.json",
        locations="FIPS",
        color="Quantile",
        scope="usa",
        color_continuous_scale="blues",
        labels={variable: variable.replace("_", " ")},
    )

    fig.update_coloraxes(showscale=False)  # Hide the color bar
    fig.update_layout(
        margin=dict(l=0, r=0, t=0, b=0),
        paper_bgcolor="white",
    )

    if output_dir:
        os.makedirs(output_dir, exist_ok=True)
        output_path = os.path.join(output_dir, f"immigration_shock_{year}.png")
        fig.write_image(output_path, width=1200, height=800, scale=3)
        print(f"Map written to {output_path}")


def map_make_all(dta_path, output_dir):
    # Generates maps/immigration_shock_{year}.png for each 5-year period (used by maps.tex)
    for i in [1980, 1985, 1990, 1995, 2000, 2005, 2010]:
        map_immigration_quantiles(dta_path, year=i, num_quantiles=200, output_dir=output_dir)


# ===========================================================================
# 4. Selection gap plot  ->  paper/figures/selection_gap.png
# ===========================================================================
#
# For each capital class, compute the gap (young - new weighted mean employment)
# for Native and Immigrant owners, then plot both groups across capital classes.

def selplot_load_data():
    cols = [
        "employment_noisy", "tabwgt", "firm_age",
        "fully_american", "fully_immigrant", "scamount",
    ]
    df = pd.read_stata(SBO_FILE, convert_categoricals=False, columns=cols)
    df = df.dropna(subset=["employment_noisy", "tabwgt"])
    return df


def selplot_compute_gaps(df, new_age, young_age, capital_classes):
    classes_str = [str(c) for c in capital_classes]
    results = {"Native": [], "Immigrant": []}

    for cls in classes_str:
        sub = df[df["scamount"] == cls]

        native_df    = sub[sub["fully_american"]  == 1]
        immigrant_df = sub[sub["fully_immigrant"] == 1]

        for name, gdf in [("Native", native_df), ("Immigrant", immigrant_df)]:
            new_df   = gdf[gdf["firm_age"].between(0, new_age)]
            young_df = gdf[gdf["firm_age"].between(new_age + 1, young_age)]

            mean_new   = wmean(new_df)
            mean_young = wmean(young_df)

            if np.isnan(mean_new) or np.isnan(mean_young):
                gap = np.nan
            else:
                gap = mean_young - mean_new

            results[name].append(gap)
            print(
                f"  Class {cls:>3} | {name:<12} | "
                f"new={mean_new:6.2f}  young={mean_young:6.2f}  gap={gap:+6.2f}"
            )

    return results


def selplot_plot_gaps(gaps, capital_classes, new_age, young_age, output_dir):
    classes_str   = [str(c) for c in capital_classes]
    display_order = list(range(len(classes_str)))
    x_labels      = [classes_str[i] for i in display_order]

    fig, ax = plt.subplots(figsize=(9, 6))

    colors  = {"Native": "#1f77b4", "Immigrant": "#d62728"}
    markers = {"Native": "o", "Immigrant": "s"}

    for name, gap_list in gaps.items():
        y = [gap_list[i] for i in display_order]
        ax.plot(
            x_labels, y,
            marker=markers[name],
            color=colors[name],
            label=name,
            linewidth=2,
            markersize=6,
        )

    ax.set_xlabel("Capital Class", fontsize=12)
    ax.set_ylabel("Selection Gap (Young Firms - New Firms)", fontsize=13)
    ax.axhline(0, color="black", linewidth=0.8, linestyle="--")
    ax.legend(fontsize=11)
    ax.grid(axis="y", linestyle="--", alpha=0.4)

    capital_labels = (
        "Capital Classes\n"
        r"1 - Less than \$5,000" + "\n"
        r"2 - \$5,000 to \$9,999" + "\n"
        r"3 - \$10,000 to \$24,999" + "\n"
        r"4 - \$25,000 to \$49,999" + "\n"
        r"5 - \$50,000 to \$99,999" + "\n"
        r"6 - \$100,000 to \$249,999" + "\n"
        r"7 - \$250,000 to \$999,999" + "\n"
        r"8 - \$1,000,000 or more"
    )
    ax.annotate(
        capital_labels,
        xy=(1, 6.5), xycoords="axes fraction",
        xytext=(0.02, 0.8), textcoords="axes fraction",
        va="top", ha="left",
        fontsize=11,
        bbox=dict(boxstyle="round,pad=0.4", facecolor="white", edgecolor="gray", alpha=0.8),
        annotation_clip=False,
    )

    fig.tight_layout()

    os.makedirs(output_dir, exist_ok=True)
    path = os.path.join(output_dir, "selection_gap.png")
    fig.savefig(path, dpi=150)
    print(f"Plot saved to {path}")
    plt.close(fig)


def selplot_make(new_age, young_age, capital_classes, output_dir):
    print(f"New firms  : age in [0, {new_age}]")
    print(f"Young firms: age in [{new_age + 1}, {young_age}]")
    print(f"Capital classes: {[str(c) for c in capital_classes]}\n")

    df   = selplot_load_data()
    gaps = selplot_compute_gaps(df, new_age, young_age, capital_classes)
    selplot_plot_gaps(gaps, capital_classes, new_age, young_age, output_dir)


# ===========================================================================
# 5. Simulated selection gap  ->  paper/figures/gap_simulation.png
# ===========================================================================
#
# Two-period general-equilibrium entry model with a financial (capital) constraint.
# Two groups differ only in their talent distribution; the simulated selection gap
# (period-2 minus period-1 mean firm size by capital bin) tests Proposition 1.

def draw_capital(n, capital_dist):
    """Draw capital for N individuals."""
    return capital_dist(n)


def optimal_labor(theta, alpha, w):
    """Unconstrained optimal labor demand from Cobb-Douglas profit maximization."""
    return (alpha * theta / w) ** (1 / (1 - alpha))


def profit(theta, k, alpha, w, lam):
    """Profit for an entrepreneur with talent theta and capital k (constrained if
    optimal labor demand exceeds lambda*k)."""
    l_unconstrained = optimal_labor(theta, alpha, w)
    l_constrained_cap = lam * k

    constrained = l_unconstrained > l_constrained_cap
    l = np.where(constrained, l_constrained_cap, l_unconstrained)

    return theta * l**alpha - w * l


def expected_profit(k, talent_dist, alpha, w, lam, n_draws):
    """Expected profit for an individual with capital k, integrating over talent."""
    theta_draws = talent_dist(n_draws)
    profits = profit(theta_draws, k, alpha, w, lam)
    return profits.mean()


def entry_decision(capital, talent_dist, alpha, w, lam, n_draws):
    """Enter entrepreneurship if expected profit (over talent) exceeds wage w."""
    enters = np.array([
        expected_profit(k, talent_dist, alpha, w, lam, n_draws) > w
        for k in capital
    ])
    return enters


def realize_firms(capital, enters, talent_dist, alpha, w, lam):
    """Entrants draw realized talent, then compute firm size and profit."""
    k_entrants = capital[enters]
    n_entrants = k_entrants.size

    theta = talent_dist(n_entrants)

    l_unconstrained = optimal_labor(theta, alpha, w)
    l_cap = lam * k_entrants
    constrained = l_unconstrained > l_cap
    labor = np.where(constrained, l_cap, l_unconstrained)

    firm_profit = theta * labor**alpha - w * labor

    return theta, labor, firm_profit, constrained


def survive_decision(firm_profit, w):
    """Firms whose realized profit >= w survive into period 2."""
    return firm_profit >= w


def period2_firms(capital_survivors, theta_survivors, alpha, w, lam, rng, sigma_z=0.5):
    """Surviving firms draw a productivity shock z (E[z]=1) and re-optimize labor."""
    mu_z = -0.5 * sigma_z**2
    z = rng.lognormal(mean=mu_z, sigma=sigma_z, size=len(capital_survivors))
    eff_theta = z * theta_survivors

    l_unconstrained = optimal_labor(eff_theta, alpha, w)
    l_cap = lam * capital_survivors
    constrained2 = l_unconstrained > l_cap
    labor2 = np.where(constrained2, l_cap, l_unconstrained)

    firm_profit2 = eff_theta * labor2**alpha - w * labor2

    return z, eff_theta, labor2, firm_profit2, constrained2


def simulate_group(capital, talent_dist, alpha, w, lam, rng, n_draws):
    """Run the full two-period simulation for one group."""
    enters = entry_decision(capital, talent_dist, alpha, w, lam, n_draws)
    theta, labor, firm_profit, constrained = realize_firms(
        capital, enters, talent_dist, alpha, w, lam
    )

    survives = survive_decision(firm_profit, w)
    capital_surv = capital[enters][survives]
    z, eff_theta, labor2, firm_profit2, constrained2 = period2_firms(
        capital_surv, theta[survives], alpha, w, lam, rng
    )

    return dict(
        capital_entrants=capital[enters],
        labor1=labor,
        firm_profit1=firm_profit,
        constrained1=constrained,
        theta1=theta,
        enters=enters,
        survives=survives,
        capital_surv=capital_surv,
        labor2=labor2,
        firm_profit2=firm_profit2,
        constrained2=constrained2,
        z=z,
        eff_theta=eff_theta,
    )


def plot_selection_gap(groups, group_labels, output_dir, n_bins=8):
    """Plot the simulated selection gap (period 2 minus period 1 mean firm size per
    capital bin) for each group on shared, pooled-capital bins."""
    all_capital1 = np.concatenate([g["capital_entrants"] for g in groups])
    bin_edges = np.quantile(all_capital1, np.linspace(0, 1, n_bins + 1))

    colors  = {"Group 1": "#1f77b4", "Group 2": "#d62728"}
    markers = {"Group 1": "o",       "Group 2": "s"}

    fig, ax = plt.subplots(figsize=(9, 6))

    for g, label in zip(groups, group_labels):
        idx1 = np.digitize(g["capital_entrants"], bin_edges[1:-1])
        idx2 = np.digitize(g["capital_surv"], bin_edges[1:-1])
        gap = []
        for i in range(n_bins):
            m1 = g["labor1"][idx1 == i].mean() if (idx1 == i).any() else np.nan
            m2 = g["labor2"][idx2 == i].mean() if (idx2 == i).any() else np.nan
            gap.append(m2 - m1)
        ax.plot(range(n_bins), gap, marker=markers[label], label=label, color=colors[label],
                linewidth=2, markersize=6)

    ax.set_xticks(range(n_bins))
    ax.set_xticklabels(range(1, n_bins + 1))
    ax.set_xlabel("Capital Class", fontsize=12)
    ax.set_ylabel("Selection Gap", fontsize=13)
    ax.axhline(0, color="black", linewidth=0.8, linestyle="--")
    ax.legend(fontsize=11)
    ax.grid(axis="y", linestyle="--", alpha=0.4)
    plt.tight_layout()

    os.makedirs(output_dir, exist_ok=True)
    path = os.path.join(output_dir, "gap_simulation.png")
    plt.savefig(path, dpi=150)
    print(f"Plot saved to {path}")
    plt.close(fig)


def print_group_stats(name, g):
    print(f"\n=== {name} - Period 1 ===")
    print(f"Entry rate:                   {g['enters'].mean():.3f}")
    print(f"Mean capital (entrants):      {g['capital_entrants'].mean():.3f}")
    print(f"Mean realized talent:         {g['theta1'].mean():.3f}")
    print(f"Mean firm size (labor):       {g['labor1'].mean():.3f}")
    print(f"Mean firm profit:             {g['firm_profit1'].mean():.3f}")
    print(f"Share constrained:            {g['constrained1'].mean():.3f}")
    print(f"\n=== {name} - Period 2 ===")
    print(f"Survival rate (of entrants):  {g['survives'].mean():.3f}")
    print(f"Mean capital (survivors):     {g['capital_surv'].mean():.3f}")
    print(f"Mean shock z:                 {g['z'].mean():.3f}")
    print(f"Mean effective theta:         {g['eff_theta'].mean():.3f}")
    print(f"Mean firm size (labor):       {g['labor2'].mean():.3f}")
    print(f"Mean firm profit:             {g['firm_profit2'].mean():.3f}")
    print(f"Share constrained:            {g['constrained2'].mean():.3f}")


def sim_make(output_dir):
    rng = np.random.default_rng(seed=42)

    # --- Parameters ---
    N = 10_000          # number of individuals per group
    ALPHA = 0.7         # labor share in Cobb-Douglas
    W = 1000.0          # market wage
    LAM = 1.0           # financial market tightness (higher = looser)
    N_THETA_DRAWS = 500 # draws for numerical integration over talent

    capital_dist = lambda n: rng.lognormal(mean=1.0, sigma=1.5, size=n)

    # --- Group talent distributions (same capital, different talent) ---
    talent_dist_1 = lambda n: rng.lognormal(mean=2.0, sigma=4.0, size=n)
    talent_dist_2 = lambda n: rng.lognormal(mean=2.0, sigma=3.0, size=n)

    # --- Simulate both groups ---
    capital_1 = draw_capital(N, capital_dist)
    capital_2 = draw_capital(N, capital_dist)

    g1 = simulate_group(capital_1, talent_dist_1, ALPHA, W, LAM, rng, N_THETA_DRAWS)
    g2 = simulate_group(capital_2, talent_dist_2, ALPHA, W, LAM, rng, N_THETA_DRAWS)

    print_group_stats("Group 1", g1)
    print_group_stats("Group 2", g2)

    plot_selection_gap([g1, g2], group_labels=["Group 1", "Group 2"], output_dir=output_dir)


# ===========================================================================
# Main
# ===========================================================================

def main():
    os.makedirs(TABLES_DIR, exist_ok=True)
    os.makedirs(MAPS_DIR, exist_ok=True)

    steps = [
        ("1. Selection gap table",
         lambda: selgap_table(NEW_AGE, YOUNG_AGE, ["8"], TABLES_DIR)),
        ("2. Capital/education table (UNUSED)",
         lambda: capeduc_table(os.path.join(TABLES_DIR, "tab_capital_educ.tex"))),
        ("3. Immigration shock maps",
         lambda: map_make_all(IMMIG_FILE, MAPS_DIR)),
        ("4. Selection gap plot",
         lambda: selplot_make(NEW_AGE, YOUNG_AGE, ["1", "2", "3", "4", "5", "6", "7", "8"], FIGURES_DIR)),
        ("5. Simulated selection gap",
         lambda: sim_make(FIGURES_DIR)),
    ]

    for name, fn in steps:
        print("\n" + "=" * 70)
        print(name)
        print("=" * 70)
        try:
            fn()
        except Exception as e:
            print(f"  [error] {name} failed: {e}")


if __name__ == "__main__":
    main()
