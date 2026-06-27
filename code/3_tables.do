
//==============================================================================
						// Main Thesis - Tables (Stata)
//==============================================================================

 /*
	Produces the Stata-generated tables:
		1. Summary stats   -> immigration_stats.tex, sbo_stats.tex
		                      (+ bds_stats.tex, UNUSED in paper)
		2. Main IV (log)   -> main_analysis.tex, pop_analysis.tex
		3. First stage/IHS -> first_stage.tex, iv_sin.tex
		4. By firm age     -> bds_firm_age.tex

	By: Akshat Kumar
	Last Updated: 26th June, 2026
*/

/*  ================================  NOTES  ================================

	INPUTS:
		- data/0_raw_data/ImmigrationShock.dta
		- data/1_clean_data/bds_analysis.dta
		- data/1_clean_data/bds_pop_analysis.dta
		- data/1_clean_data/wage_bds.dta
		- data/1_clean_data/bds_age_analysis.dta
		- data/1_clean_data/survey_data.dta

	OUTPUTS:
		- paper/tables/{immigration_stats,bds_stats,sbo_stats}.tex
		- paper/tables/{main_analysis,pop_analysis}.tex
		- paper/tables/{first_stage,iv_sin}.tex
		- paper/tables/bds_firm_age.tex

	DEPENDENCIES:
		- estout, ivreghdfe, reghdfe

*/

 **************** SET MAIN DO-FILE ARGUMENTS ****************

	// Clear all and set large data arguments.
	clear all
	set memory 1500m
	set maxvar 10000
	set more off
	set seed 2929

	// Set Graph style
// 	ssc install schemepack, replace // Uncomment if missing required package
	set scheme tab2


*********************************** HEADER ***********************************/

************************ Define user-specific project paths  *******************

	local system_string `c(username)' // Get Stata dir.
	display "Current user, `c(username)' `c(machine_type)' `c(os)'."

	* Akshat Kumar
	if inlist( "`c(username)'" , "aksha") {

		local workingdir "C:/Users/aksha/Dropbox/Personal/thesis/main_thesis"
		}

	* Replicators: add your own branch here, e.g.
	* else if inlist( "`c(username)'" , "yourusername") {
	*	local workingdir "/path/to/main_thesis"
	*	}

	else {
		* Fallback: assume the current directory is the project root.
		* master.sh cd's to the repo root before launching Stata, so this resolves
		* automatically. Running this .do by hand? cd to the repo root first
		* (or add your own username branch above).
		local workingdir "`c(pwd)'"
		noisily display as text "No username profile matched; using current directory as project root: `workingdir'"
	}

	di "This project is working from `workingdir'"

*==============================================================================*

************************** Set Up Directories **********************************

	// Directory with data
	local datadir "`workingdir'/data"

	// Raw data
	local rawdir "`datadir'/0_raw_data"

	// Clean data (inputs)
	local cleandir "`datadir'/1_clean_data"

	// Directory for tex tables
	local texdir "`workingdir'/paper/tables"

//============================== END HEADER =====================================


********************************** 1. Summary Stats ***************************

	*********** Immigration Data (immigration_stats.tex) ***********

	clear

	// Load in data
	use "`rawdir'/ImmigrationShock.dta"

	count
	// Result: 21,987

	// Change Labels
	label var Immigration "5-year Immigration"
	label var ImmigrationShock "Immigration Instrument"
	label var ImmigrationNonEuropean "5-year Non-European Immigration"

	// Generate Table
	estpost summarize ImmigrationShock ImmigrationNonEuropean Immigration

	esttab using "`texdir'/immigration_stats.tex", replace ///
    cells("count(fmt(%12.0f)) mean(fmt(%12.3f)) min(fmt(%12.3f)) max(fmt(%12.3f)) sd(fmt(%12.3f))") ///
    label noobs nonumber nomtitles ///
    booktabs ///
    collabels("N" "Mean" "Min" "Max" "SD") ///
    title("Immigration Data \label{tab:immigration}") ///
    note("All observations are at the county 5-year level. Immigration numbers are reported in 1000s.")

	clear

	*********** BDS Data (bds_stats.tex - UNUSED) ***********

	// Load in data
	use "`cleandir'/bds_analysis.dta"

	count
	// Result: 146,924

	// Keep years of interest
	keep if inrange(year, 1978, 2010)

	count
	// Result: 105,402

	// Change Labels
	label var firms  "Firm Count"
	label var estabs "Establishment Count"
	label var emp "Employment"
	label var estabs_entry "Establishment Births"
	label var estabs_entry_rate "Establishment Entry Rate"
	label var estabs_exit "Establishment Exits"
	label var estabs_exit_rate "Establishment Exit Rate"
	label var job_creation "Job Creation"
	label var job_creation_births "Job Creation (New Estabs.)"
	label var job_creation_continuers "Job Creation (Continuers)"
	label var job_destruction "Job Destruction"
	label var job_destruction_deaths "Job Destruction (Dead Estabs.)"
	label var job_destruction_continuers "Job Destruction (Continuers)"
	label var net_job_creation "Net Job Creation"

	// Generate Table
	estpost summarize firms estabs emp estabs_entry estabs_entry_rate estabs_exit estabs_exit_rate job_creation job_creation_births job_creation_continuers job_destruction job_destruction_deaths job_destruction_continuers net_job_creation

	esttab using "`texdir'/bds_stats.tex", replace ///
	cells("count(fmt(%12.0fc)) mean(fmt(%12.1fc)) min(fmt(%12.0fc)) max(fmt(%12.1fc)) sd(fmt(%12.1fc))") ///
    label noobs nonumber nomtitles ///
    booktabs ///
    collabels("N" "Mean" "Min" "Max" "SD") ///
    title("Business Dynamics Data \label{tab:bds}") ///
    note("All observations are at the county year level. Data is from 1978 to 2010.")

	clear

	*********** SBO Data (sbo_stats.tex - weighted) ***********

	// Load in data
	use "`cleandir'/survey_data.dta"

	count
	// Result: 2,165,680

	// Fix variable ranges
	replace familybus=. if familybus ==0
	replace familybus=0 if familybus ==2
	replace startanother=. if startanother==0
	replace startanother=0 if startanother==2
	replace homebased=. if homebased==0
	replace homebased=0 if homebased==2
	replace fulltime=. if fulltime==0
	replace fulltime=0 if fulltime==2

	// Generate var for spouse owned
	gen spouse=.
	replace spouse=1 if inrange(husbwife, 1, 3)
	replace spouse=0 if husbwife==4

	// Add labels
	label var firm_age "Firm Age"
	label var employment_noisy "Employment"
	label var payroll_noisy "Payroll"
	label var receipts_noisy "Receipts"
	label var familybus "Family Business"
	label var spouse "Couple-Owned"
	label var homebased "Home Based Business"
	label var fulltime "Has Full Time Employees"

	// Define your variables of interest
	local rowvars "firm_age employment_noisy payroll_noisy receipts_noisy familybus spouse homebased fulltime"

	// Get weighted observation counts
	sum tabwgt
	local n_all: display %12.0fc r(sum)
	sum tabwgt if fully_american == 1
	local n_american: display %12.0fc r(sum)
	sum tabwgt if fully_immigrant == 1
	local n_immigrant: display %12.0fc r(sum)
	sum tabwgt if partly_american == 1
	local n_mixed: display %12.0fc r(sum)

	// Create the table with weights
	eststo all: estpost summarize `rowvars' [aweight=tabwgt]
	eststo american: estpost summarize `rowvars' [aweight=tabwgt] if fully_american == 1
	eststo immigrant: estpost summarize `rowvars' [aweight=tabwgt] if fully_immigrant == 1
	eststo mixed: estpost summarize `rowvars' [aweight=tabwgt] if partly_american == 1

	esttab all american immigrant mixed using "`texdir'/sbo_stats.tex", replace ///
		cells(mean(fmt(%12.2fc)) sd(par fmt(%12.2fc))) ///
		incelldelimiter("") ///
		label noobs nonumber ///
		booktabs ///
		nomtitles ///
		collabels(none) ///
		prehead("\begin{table}[htbp]\centering\caption{Survey Data by Ownership Type \label{tab:sbo}}\begin{tabular}{l*{4}{c}}\toprule & (1) & (2) & (3) & (4) \\") ///
		posthead("& All & Fully American & Fully Immigrant & Mixed \\ \midrule \midrule") ///
		prefoot("\midrule") ///
		postfoot("Observations & `n_all' & `n_american' & `n_immigrant' & `n_mixed' \\\bottomrule\end{tabular}\par\smallskip\raggedright\footnotesize Notes: All observations are at the firm/business level. Cell values report weighted means with weighted standard deviations in parentheses. Observation counts reflect weighted number of firms.\end{table}")
	eststo clear


********************************** 2. Main IV (log) ***************************

	*********** Main IV (main_analysis.tex) ***********

	clear

	// Load in data
	use "`cleandir'/wage_bds"

	eststo clear
	eststo b1: ivreghdfe ln_annualaveragepay ///
		(ln_ImmigrationNonEuropean = ImmigrationShock), ///
		absorb(st year) cluster(st)
	estadd scalar pval = 2*ttail(e(df_r), abs(_b[ln_ImmigrationNonEuropean]/_se[ln_ImmigrationNonEuropean]))

	clear

	// Load in data
	use "`cleandir'/bds_pop_analysis"

	// Make table
	eststo b2: ivreghdfe ln_avg_emp ///
		(ln_ImmigrationNonEuropean = ImmigrationShock), ///
		absorb(st year) cluster(st)
	estadd scalar pval = 2*ttail(e(df_r), abs(_b[ln_ImmigrationNonEuropean]/_se[ln_ImmigrationNonEuropean]))

	eststo b3: ivreghdfe avg_estabs_entry_rate ///
		(ln_ImmigrationNonEuropean = ImmigrationShock), ///
		absorb(st year) cluster(st)
	estadd scalar pval = 2*ttail(e(df_r), abs(_b[ln_ImmigrationNonEuropean]/_se[ln_ImmigrationNonEuropean]))

	eststo b4: ivreghdfe avg_estabs_exit_rate ///
		(ln_ImmigrationNonEuropean = ImmigrationShock), ///
		absorb(st year) cluster(st)
	estadd scalar pval = 2*ttail(e(df_r), abs(_b[ln_ImmigrationNonEuropean]/_se[ln_ImmigrationNonEuropean]))

	esttab b1 b2 b3 b4 using "`texdir'/main_analysis.tex", ///
    replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    booktabs ///
    fragment ///
    label ///
    collabels(none) ///
    mtitles("Wages" "Firm Size" "Entry Rate" "Exit Rate" ) ///
    stats(N cdf pval, fmt(0 1 3) labels("N" "F-stat" "P-value")) ///
	varlabels(ln_ImmigrationNonEuropean "Log(Immigration)") ///
    nobaselevels nonumbers ///
	prehead("\begin{table}[htbp] \centering" ///
    "\caption{Effects on Business Dynamics}" "\label{tab:main}" ///
	"\newsavebox{\boxmain} \newlength{\tablemain}" ///
	"\savebox{\boxmain}{\begin{tabular}{lcccc} \toprule" ///
	"& (1) & (2) & (3) & (4)  \\ \cmidrule(lr){2-5}") ///
	postfoot("\bottomrule \end{tabular} }" ///
	"\settowidth{\tablemain}{\usebox{\boxmain}}" ///
	"\usebox{\boxmain} \vspace{0.5em} " ///
	"\parbox{\tablemain}{\footnotesize \textit{Notes:} * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Standard errors clustered at the state-level. Cragg-Donald Wald F-statistic reported. Column (1) \& (2) are logged, (3) \& (4) are past 5-year averages. Population is past 5-year average except 2010 population which is the average from 2006 to 2009. Wages data only covers 1990-2010. All columns include State and Time FE.}" ///
" \end{table}")

	clear

	*********** IV with Pop. (pop_analysis.tex) ***********

	// Load in data
	use "`cleandir'/wage_bds"

	eststo clear
	eststo c1: ivreghdfe ln_annualaveragepay pop_avg ///
		(ln_ImmigrationNonEuropean = ImmigrationShock), ///
		absorb(st year) cluster(st)
	estadd scalar pval = 2*ttail(e(df_r), abs(_b[ln_ImmigrationNonEuropean]/_se[ln_ImmigrationNonEuropean]))

	clear

	// Load in data
	use "`cleandir'/bds_pop_analysis"

	// Make table
	eststo c2: ivreghdfe ln_avg_emp pop_avg ///
		(ln_ImmigrationNonEuropean = ImmigrationShock), ///
		absorb(st year) cluster(st)
	estadd scalar pval = 2*ttail(e(df_r), abs(_b[ln_ImmigrationNonEuropean]/_se[ln_ImmigrationNonEuropean]))

	eststo c3: ivreghdfe avg_estabs_entry_rate pop_avg ///
		(ln_ImmigrationNonEuropean = ImmigrationShock), ///
		absorb(st year) cluster(st)
	estadd scalar pval = 2*ttail(e(df_r), abs(_b[ln_ImmigrationNonEuropean]/_se[ln_ImmigrationNonEuropean]))

	eststo c4: ivreghdfe avg_estabs_exit_rate pop_avg ///
		(ln_ImmigrationNonEuropean = ImmigrationShock), ///
		absorb(st year) cluster(st)
	estadd scalar pval = 2*ttail(e(df_r), abs(_b[ln_ImmigrationNonEuropean]/_se[ln_ImmigrationNonEuropean]))

	esttab c1 c2 c3 c4 using "`texdir'/pop_analysis.tex", ///
    replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    booktabs ///
    fragment ///
    label ///
    collabels(none) ///
    mtitles("Wages" "Firm Size" "Entry Rate" "Exit Rate" ) ///
    stats(N cdf pval, fmt(0 1 3) labels("N" "F-stat" "P-value")) ///
    order(ln_ImmigrationNonEuropean pop_avg) ///
	varlabels(ln_ImmigrationNonEuropean "Log(Immigration)" pop_avg  "Population") ///
    nobaselevels nonumbers ///
	prehead("\begin{table}[htbp] \centering" ///
	"\caption{Effects on Business Dynamics with Population Change}" ///
	"\label{tab:pop} \newsavebox{\boxpop} \newlength{\tablepop}" ///
	"\savebox{\boxpop}{\begin{tabular}{lcccc} \toprule" ///
	"& (1) & (2) & (3) & (4)  \\ \cmidrule(lr){2-5}") ///
	postfoot("\bottomrule \end{tabular} }" ///
	"\settowidth{\tablepop}{\usebox{\boxpop}}" ///
	"\usebox{\boxpop} \vspace{0.5em} " ///
	"\parbox{\tablepop}{\footnotesize \textit{Notes:} * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Standard errors clustered at the state-level. Cragg-Donald Wald F-statistic reported. Column (1) \& (2) are logged, (3) \& (4) are past 5-year averages. Population is past 5-year average except 2010 population which is the average from 2006 to 2009. All columns include State and Time FE.}" ///
" \end{table}")

	clear


********************************** 3. First Stage & IHS ***********************

	*********** First Stage (first_stage.tex) ***********

	// Load in data
	use "`cleandir'/bds_analysis"

	count
	// Result: 146,924

	keep if _merge == 3
	count
	// Result: 21,854

	// Column 1: State + Time FE
	reghdfe ImmigrationNonEuropean ImmigrationShock, ///
		absorb(st year) cluster(st)
	eststo f1
	estadd scalar pval = Ftail(e(df_m), e(df_r), e(F))

	// Column 2: State + Time + State-Time FE
	reghdfe ImmigrationNonEuropean ImmigrationShock, ///
		absorb(st year st#year) cluster(st)
	eststo f2
	estadd scalar pval = Ftail(e(df_m), e(df_r), e(F))

	// Column 3: County + Time FE
	reghdfe ImmigrationNonEuropean ImmigrationShock, ///
		absorb(cty year) cluster(st)
	eststo f3
	estadd scalar pval = Ftail(e(df_m), e(df_r), e(F))

	// Add FE indicators
	foreach m in f1 f2 f3 {
		estimates restore `m'
		estadd local timefe "Yes"
	}
	estimates restore f1
	estadd local geofe "State"
	estadd local stfe "No"

	estimates restore f2
	estadd local geofe "State"
	estadd local stfe "Yes"

	estimates restore f3
	estadd local geofe "County"
	estadd local stfe "No"

	// Export table
	esttab f1 f2 f3 using "`texdir'/first_stage.tex", ///
		replace ///
    varlabels(ImmigrationShock "Immigration Shock") ///
    se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    b(3) ///
	nomtitles ///
	nonumbers ///
	drop(_cons) ///
    parentheses ///
    stats(N r2 pval geofe timefe stfe, ///
        fmt(0 3 3 0 0 0) ///
        labels("N" "R$^2$" "P-value" ///
            "Geography FE" "Time FE" "State-Time FE")) ///
    prehead("\begin{table}[htbp]" "\centering" ///
    "\caption{IV First Stage}" ///
    "\label{tab:firststage}" ///
    "\begin{tabular}{l*{3}{c}}" "\toprule" ///
    "& \multicolumn{3}{c}{Non-European Migration} \\" ///
    "\cmidrule(lr){2-4}" ///
    "& (1) & (2) & (3) \\") ///
    posthead("\midrule") ///
    prefoot("\midrule") ///
    postfoot("\bottomrule" ///
        "\multicolumn{4}{@{}l@{}}{\footnotesize \textit{Notes:} * p$<$0.10, ** p$<$0.05, *** p$<$0.01.}" "\\" ///
        "\multicolumn{4}{@{}l@{}}{\footnotesize Standard errors clustered at the state level.}" "\\" ///
        "\end{tabular}" "\end{table}") ///
    nonotes

	clear

	*********** Main IV (IHS) (iv_sin.tex) ***********

	// Load in data
	use "`cleandir'/wage_bds"
	eststo clear

	// Generate IHS variables
	gen ihs_annualaveragepay = asinh(annualaveragepay)
	gen ihs_ImmigrationNonEuropean = asinh(ImmigrationNonEuropean)
	gen ihs_ImmigrationShock = asinh(ImmigrationShock)

	eststo b1: ivreghdfe ihs_annualaveragepay ///
		(ihs_ImmigrationNonEuropean = ihs_ImmigrationShock), ///
		absorb(st year) cluster(st)
	estadd scalar pval = 2*ttail(e(df_r), abs(_b[ihs_ImmigrationNonEuropean]/_se[ihs_ImmigrationNonEuropean]))

	clear
	// Load in data
	use "`cleandir'/bds_pop_analysis"

	// Generate IHS variables
	gen ihs_avg_emp = asinh(avg_emp)
	gen ihs_avg_estabs_entry_rate = asinh(avg_estabs_entry_rate)
	gen ihs_avg_estabs_exit_rate = asinh(avg_estabs_exit_rate)
	gen ihs_ImmigrationNonEuropean = asinh(ImmigrationNonEuropean)
	gen ihs_ImmigrationShock = asinh(ImmigrationShock)

	// Firm Size
	eststo b2: ivreghdfe ihs_avg_emp  ///
		(ihs_ImmigrationNonEuropean = ihs_ImmigrationShock), ///
		absorb(st year) cluster(st)
	estadd scalar pval = 2*ttail(e(df_r), abs(_b[ihs_ImmigrationNonEuropean]/_se[ihs_ImmigrationNonEuropean]))

	// Entry Rate
	eststo b3: ivreghdfe avg_estabs_entry_rate ///
		(ihs_ImmigrationNonEuropean = ihs_ImmigrationShock), ///
		absorb(st year) cluster(st)
	estadd scalar pval = 2*ttail(e(df_r), abs(_b[ihs_ImmigrationNonEuropean]/_se[ihs_ImmigrationNonEuropean]))

	// Exit Rate
	eststo b4: ivreghdfe avg_estabs_exit_rate ///
		(ihs_ImmigrationNonEuropean = ihs_ImmigrationShock), ///
		absorb(st year) cluster(st)
	estadd scalar pval = 2*ttail(e(df_r), abs(_b[ihs_ImmigrationNonEuropean]/_se[ihs_ImmigrationNonEuropean]))

	// Make IHS Main IV Table
	esttab b1 b2 b3 b4 using "`texdir'/iv_sin.tex", ///
    replace ///
    substitute(\_ _) ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    booktabs ///
    fragment ///
    label ///
    collabels(none) ///
    mtitles("Wages" "Firm Size" "Entry Rate" "Exit Rate" ) ///
    stats(N cdf pval, fmt(0 1 3) labels("N" "F-stat" "P-value")) ///
	varlabels(ihs_ImmigrationNonEuropean "IHS(Immigration)") ///
    nobaselevels nonumbers ///
	prehead("\begin{table}[htbp] \centering" ///
    "\caption{Inverse Hyperbolic Sine Effects on Business Dynamics}" "\label{tab:sin_iv}" ///
	"\newsavebox{\boxsine} \newlength{\tablesine}" ///
	"\savebox{\boxsine}{\begin{tabular}{lcccc} \toprule" ///
	"& (1) & (2) & (3) & (4)  \\ \cmidrule(lr){2-5}") ///
	postfoot("\bottomrule \end{tabular} }" ///
	"\settowidth{\tablesine}{\usebox{\boxsine}}" ///
	"\usebox{\boxsine} \vspace{0.5em} " ///
	"\parbox{\tablesine}{\footnotesize \textit{Notes:} * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Standard errors clustered at the state-level. Cragg-Donald Wald F-statistic reported. Column (1) \& (2) are inverse hyperbolic sined, (3) \& (4) are past 5-year averages. All columns include State and Time FE.}" ///
" \end{table}")

	clear


********************************** 4. By Firm Age ****************************

	// Load in data
	use "`cleandir'/bds_age_analysis"

	count
	// Result: 93,660

	drop if	firm_age == "censored"

	eststo clear

	*********** New Firms ***********
	preserve

	keep if firm_age == "new"

	eststo b1: ivreghdfe ln_avg_emp ///
		(ln_ImmigrationNonEuropean = ImmigrationShock), ///
			absorb(st year) cluster(st)
	estadd scalar pval = 2*ttail(e(df_r), abs(_b[ln_ImmigrationNonEuropean]/_se[ln_ImmigrationNonEuropean]))

		cap program drop emptyest
	program emptyest, eclass
		ereturn post
		ereturn local cmd "emptyest"
	end

	emptyest
	estimates store a1

	restore

	*********** Young Firms ***********
	preserve

	keep if firm_age == "young"
	eststo a2: ivreghdfe avg_estabs_death_rate ///
		(ln_ImmigrationNonEuropean = ImmigrationShock), ///
			absorb(st year) cluster(st)
	estadd scalar pval = 2*ttail(e(df_r), abs(_b[ln_ImmigrationNonEuropean]/_se[ln_ImmigrationNonEuropean]))

	eststo b2: ivreghdfe ln_avg_emp ///
		(ln_ImmigrationNonEuropean = ImmigrationShock), ///
			absorb(st year) cluster(st)
	estadd scalar pval = 2*ttail(e(df_r), abs(_b[ln_ImmigrationNonEuropean]/_se[ln_ImmigrationNonEuropean]))

	restore

	*********** Medium Firms ***********
	preserve

	keep if firm_age == "medium"
	eststo a3: ivreghdfe avg_estabs_death_rate ///
		(ln_ImmigrationNonEuropean = ImmigrationShock), ///
			absorb(st year) cluster(st)
	estadd scalar pval = 2*ttail(e(df_r), abs(_b[ln_ImmigrationNonEuropean]/_se[ln_ImmigrationNonEuropean]))

	eststo b3: ivreghdfe ln_avg_emp ///
		(ln_ImmigrationNonEuropean = ImmigrationShock), ///
			absorb(st year) cluster(st)
	estadd scalar pval = 2*ttail(e(df_r), abs(_b[ln_ImmigrationNonEuropean]/_se[ln_ImmigrationNonEuropean]))

	restore

	*********** Old Firms ***********
	preserve

	keep if firm_age == "old"
	eststo a4: ivreghdfe avg_estabs_death_rate ///
		(ln_ImmigrationNonEuropean = ImmigrationShock), ///
			absorb(st year) cluster(st)
	estadd scalar pval = 2*ttail(e(df_r), abs(_b[ln_ImmigrationNonEuropean]/_se[ln_ImmigrationNonEuropean]))

	eststo b4: ivreghdfe ln_avg_emp ///
		(ln_ImmigrationNonEuropean = ImmigrationShock), ///
			absorb(st year) cluster(st)
	estadd scalar pval = 2*ttail(e(df_r), abs(_b[ln_ImmigrationNonEuropean]/_se[ln_ImmigrationNonEuropean]))

	restore

	*********** Make Table (bds_firm_age.tex) ***********

	// Panel A: Exit (death) rate
	esttab a1 a2 a3 a4 using "`texdir'/bds_firm_age.tex", ///
    replace ///
    mtitles("New" "Young" "Medium" "Old") ///
    varlabels(ln_ImmigrationNonEuropean "Log(Immigration)") ///
    nonumbers ///
    se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    b(3) ///
    parentheses ///
    stats(N cdf pval, fmt(0 1 3) labels("N" "F-stat" "P-value")) ///
	prehead("\begin{table}[htbp]" "\centering" "\caption{Heterogeneous Effects by Firm Age} \label{tab:bdsage}" "\begin{tabular}{l*{4}{c}}" "\hline" "\hline" "& (1) & (2) & (3) & (4) \\" "\cmidrule(lr){2-5}") ///
    posthead("\hline \multicolumn{5}{l}{\textit{Panel A: 5-year Average Exit Rate}}\\ \hline") ///
    prefoot("\hline") ///
    postfoot("") ///
    nonotes

	// Panel B: Log firm size (employment)
	esttab b1 b2 b3 b4 using "`texdir'/bds_firm_age.tex", ///
    append ///
    nomtitles ///
    varlabels(ln_ImmigrationNonEuropean "Log(Immigration)") ///
    nonumbers ///
    se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    b(3) ///
    parentheses ///
    stats(N cdf pval, fmt(0 1 3) labels("N" "F-stat" "P-value")) ///
    prehead("\hline \multicolumn{5}{l}{\textit{Panel B: Log of 5-year Firm Size}} \\") ///
    prefoot("\hline") ///
	postfoot("\hline \hline" ///
	"\multicolumn{5}{@{}l@{}}{\footnotesize  \textit{Notes:} * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Standard errors clustered at the}" "\\" ///
	"\multicolumn{5}{@{}l@{}}{\footnotesize state-level.  Cragg-Donald Wald F-statistic reported Young: 1 to 5 years, }" "\\" ///
	"\multicolumn{5}{@{}l@{}}{\footnotesize Medium: 6 to 10 years, and Old: 11+ years. All columns include State}" "\\" ///
	"\multicolumn{5}{@{}l@{}}{\footnotesize and Time FE.}" "\\" ///
    "\end{tabular}" "\end{table}")
