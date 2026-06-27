
//==============================================================================
						// Main Thesis - Build Analysis Data
//==============================================================================

 /*
	Builds every analysis-ready .dta from raw inputs, in dependency order:
		1. BDS          -> bds_analysis.dta
		2. Population   -> bds_pop_analysis.dta
		3. Wage         -> wage_bds.dta
		4. BDS by age   -> bds_age_analysis.dta
		5. Survey (SBO) -> survey_data.dta, sbo_new.dta

	By: Akshat Kumar
	Last Updated: 26th June, 2026
*/

/*  ================================  NOTES  ================================

	INPUTS:
		- data/0_raw_data/bds2023_st_cty.csv
		- data/0_raw_data/bds2023_st_cty_eac.csv
		- data/0_raw_data/ImmigrationShock.dta
		- data/0_raw_data/pums.csv
		- data/0_raw_data/county_population.dta
		- data/0_raw_data/qcew_data/wage_data_combined.csv   (from 1_download_data.py)

	OUTPUTS:
		- data/1_clean_data/bds_analysis.dta
		- data/1_clean_data/bds_pop_analysis.dta
		- data/1_clean_data/wage_bds.dta
		- data/1_clean_data/bds_age_analysis.dta
		- data/1_clean_data/survey_data.dta
		- data/1_clean_data/sbo_new.dta

	DEPENDENCIES:
		- (built-in commands only)

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

	// Clean data (outputs)
	local cleandir "`datadir'/1_clean_data"

//============================== END HEADER =====================================


********************************** 1. BDS Data ********************************

	clear

	// Load in data
	import delimited "`rawdir'/bds2023_st_cty.csv"

	count
	// Result: 146,924

	// Create county identifier
	gen county = string(st, "%02.0f") + string(cty, "%03.0f") + "0"
	destring county, replace

	// Replace X with 0 for columns of interest
	local varlist "estabs emp estabs_entry_rate estabs_exit_rate job_creation_rate job_destruction_rate"
	foreach var of local varlist {
		replace `var' = "0" if `var' == "X"
		destring `var', replace force
	}

	// Calculate log growth rates
	gen ln_estabs = ln(estabs)
	bysort county (year): gen estabs_change = estabs[_n] - estabs[_n-4]
	bysort county (year): gen ln_estabs_change = ln_estabs[_n] - ln_estabs[_n-4]

	// Generate avg employment
	gen avg_emp = emp / estabs
	gen ln_avg_emp = ln(avg_emp)
	bysort county (year): gen avg_emp_change = avg_emp[_n] - avg_emp[_n-4]
	bysort county (year): gen ln_avg_emp_change = ln_avg_emp[_n] - ln_avg_emp[_n-4]

	// Construct 5-year averages
	local variables "estabs_entry_rate estabs_exit_rate job_creation_rate job_destruction_rate"
	foreach var of local variables {
		bysort county (year): gen avg_`var' = ///
			(`var'[_n] + `var'[_n-1] + `var'[_n-2] + ///
			  `var'[_n-3] + `var'[_n-4])/5
		gen ln_avg_`var' = ln(avg_`var')
		gen `var'_5_change = `var'[_n] - `var'[_n-4]
	}

	// Merge with immigration data
	rename year Year
	rename county CountyCode
	merge 1:1 CountyCode Year using "`rawdir'/ImmigrationShock"

	drop if _merge == 2

	rename Year year
	rename CountyCode county

	// Convert it to log terms
	gen ln_ImmigrationNonEuropean = ln(ImmigrationNonEuropean)

	save "`cleandir'/bds_analysis.dta", replace


********************************** 2. Population *******************************

	clear

	// Load in data
	use "`rawdir'/county_population.dta"

	count
	// Result: 6,346

	// Keep observations of interest
	drop if region == .
	drop if county_fips == 0

	count
	// Result: 3,143

	// Gen county identifier
	gen county = fips + "0"
	destring county, replace force

	// Keep columns of interest
	drop pop2010* pop201* pop19904 base20104

	// Reshape
	reshape long pop, i(county) j(year)

	count
	// Result: 125,720

	// Merge with BDS
	merge 1:1 county year using "`cleandir'/bds_analysis.dta", generate(_merge2)

	// Generate lagged population
	bysort county (year): gen pop_lag = pop[_n-1]

	// Generate 5-year averages for pop
	bysort county (year): gen pop_avg = cond(year == 2010, ///
	    (pop + pop[_n-1] + pop[_n-2] + pop[_n-3]) / 4, ///
	    (pop + pop[_n-1] + pop[_n-2] + pop[_n-3] + pop[_n-4]) / 5)

	// Generate 5-year lag for pop
	bysort county (year): gen pop_5_lag = cond(year == 2010, ///
	    pop[_n-3], ///
	    pop[_n-4])

	// Keep years of interest
	keep if inlist(year, 1980, 1985, 1990, 1995, 2000, 2005, 2010)

	// Keep matched
	keep if _merge2 == 3

	count
	// Result: 18,786

	save "`cleandir'/bds_pop_analysis.dta", replace


********************************** 3. Wage Data *******************************

	clear

	// Import Data
	import delimited "`rawdir'/qcew_data/wage_data_combined.csv", bindquote(strict) stripquote(yes)

	count
	// Result: 1,793,092

	// Filter for annual private data
	keep if own == 5 & naics == 10

	count
	// Result: 107,851

	gen county = string(st, "%02.0f") + string(cnty, "%03.0f") + "0"
	destring county, replace force

	// Calculate log growth rates
	gen ln_annualaveragepay = ln(annualaveragepay)
	bysort county (year): gen annualaveragepay_change = annualaveragepay[_n] - annualaveragepay[_n-4]
	bysort county (year): gen ln_annualaveragepay_change = ln_annualaveragepay[_n] - ln_annualaveragepay[_n-4]

	// Merge data
	merge 1:1 county year using "`cleandir'/bds_pop_analysis.dta", generate(_mergenew)

	keep if _mergenew == 3

	save "`cleandir'/wage_bds.dta", replace


********************************** 4. BDS by Firm Age *************************

	clear

	// Load in data
	import delimited "`rawdir'/bds2023_st_cty_eac.csv"

	count
	// Result: 734,620

	// Create county identifier
	gen county = string(st, "%02.0f") + string(cty, "%03.0f") + "0"

	// Destring all variables
	destring year st cty county, replace force

	// Create firm_age categorical variable from eagecoarse
	gen firm_age = ""
	replace firm_age = "new" if eagecoarse == "a) 0"
	replace firm_age = "young" if eagecoarse == "b) 1 to 5"
	replace firm_age = "medium" if eagecoarse == "c) 6 to 10"
	replace firm_age = "old" if eagecoarse == "d) 11+"
	replace firm_age = "censored" if eagecoarse == "e) Left Censored"

	// Encode as labeled numeric variable
	encode firm_age, gen(firm_age_cat)

	// Replace X with 0 for columns of interest
	local varlist "estabs emp firmdeath_estabs estabs_entry_rate estabs_exit_rate job_creation_rate job_destruction_rate"
	foreach var of local varlist {
		replace `var' = "0" if `var' == "X"
		destring `var', replace force
	}

	// Calculate log growth rates
	gen ln_estabs = ln(estabs)
	bysort county firm_age (year): gen estabs_change = estabs[_n] - estabs[_n-5]
	bysort county firm_age (year): gen ln_estabs_change = ln_estabs[_n] - ln_estabs[_n-5]

	// Generate avg employment
	gen avg_emp = emp / estabs
	gen ln_avg_emp = ln(avg_emp)
	bysort county firm_age (year): gen avg_emp_change = avg_emp[_n] - avg_emp[_n-5]
	bysort county firm_age (year): gen ln_avg_emp_change = ln_avg_emp[_n] - ln_avg_emp[_n-5]

	// Generate Estab Death Rate
	bysort county firm_age (year): gen estabs_death_rate = 100*(2*firmdeath_estabs[_n]/(estabs[_n]+estabs[_n-1]))

	// Generate 5-year averages
	local variables "estabs_death_rate estabs_entry_rate estabs_exit_rate job_creation_rate job_destruction_rate"
	foreach var of local variables {
		bysort county firm_age (year): gen avg_`var' = ///
			(`var'[_n] + `var'[_n-1] + `var'[_n-2] + ///
			  `var'[_n-3] + `var'[_n-4])/5
		gen ln_avg_`var' = ln(avg_`var')
	}

	// Keep every 5th year only
	keep if inlist(year, 1985, 1990, 1995, 2000, 2005, 2010)

	// Merge with immigration data
	rename year Year
	rename county CountyCode
	merge m:1 CountyCode Year using "`rawdir'/ImmigrationShock"

	keep if _merge == 3

	rename Year year
	rename CountyCode county

	// Generate Log
	gen ln_ImmigrationNonEuropean = ln(ImmigrationNonEuropean)

	save "`cleandir'/bds_age_analysis.dta", replace


********************************** 5. Survey (SBO) ****************************

	clear

	// Load in raw SBO PUMS
	import delimited "`rawdir'/pums.csv"

	count
	// Result: 2,165,680

	// Rename variables
	rename fipst state

	// Generate Average Payroll
	gen avg_payroll = payroll_noisy/employment_noisy

	*********************** Firm Age ***********************

	// Generate Birth year
	gen birth_yr = .
	replace birth_yr = 1980 if established == "1"
	replace birth_yr = 1985 if established == "2"
	replace birth_yr = 1995 if established == "3"
	replace birth_yr = 2001 if established == "4"
	replace birth_yr = 2003 if established == "5"
	replace birth_yr = 2004 if established == "6"
	replace birth_yr = 2005 if established == "7"
	replace birth_yr = 2006 if established == "8"
	replace birth_yr = 2007 if established == "9"

	// Generate Firm age
	gen firm_age = 2007 - birth_yr

	*********************** Owner Type ***********************

	// Count US-born and foreign-born owners
	egen count_american = anycount(bornus1 bornus2 bornus3 bornus4), values(1)
	egen count_immigrant = anycount(bornus1 bornus2 bornus3 bornus4), values(2)

	// Create categories
	gen fully_american = (count_american > 0 & count_immigrant == 0)
	gen fully_immigrant = (count_immigrant > 0 & count_american == 0)
	gen partly_american = (count_american > 0 & count_immigrant > 0)

	drop count_american count_immigrant

	count if fully_american == 1
	// Result: 1,081,833

	count if fully_immigrant == 1
	// Result: 157,696

	count if partly_american == 1
	// Result: 52,788

	// Save cleaned survey data
	save "`cleandir'/survey_data.dta", replace

	*********** Assign nativity for mixed firms via top manager ***********

	use "`cleandir'/survey_data.dta", clear

	count
	// Result: 2,165,680

	* Save part 1 as temp file
	preserve
	drop if partly_american == 1
	tempfile part1
	save `part1'
	restore

	* Keep part 2 and process it
	keep if partly_american == 1

	forvalues i = 1/4 {
		gen imm`i' = .
		gen nat`i' = .
		replace imm`i' = 1 if manage`i' == 1 & bornus`i' == 2
		replace nat`i' = 1 if manage`i' == 1 & bornus`i' == 1
	}

	egen imm_man = rowtotal(imm1 imm2 imm3 imm4)
	egen nat_man = rowtotal(nat1 nat2 nat3 nat4)

	gen nat_bus = .
	gen imm_bus = .

	replace imm_bus = 1 if imm_man > 0 & nat_man == 0 & partly_american == 1
	replace nat_bus = 1 if nat_man > 0 & imm_man == 0 & partly_american == 1

	gen multi_man = 1 if imm_bus != 1 & nat_bus != 1 & partly_american == 1

	* Set pct to missing if the owner is not a manager
	forvalues i = 1/4 {
		gen pct_man`i' = pct`i' if manage`i' == 1
	}

	* Find max ownership among managers
	egen max_pct = rowmax(pct_man1 pct_man2 pct_man3 pct_man4)

	* Among those tied at max, check bornus values
	gen has_american = 0
	gen has_foreign = 0
	gen tie_count = 0
	forvalues i = 1/4 {
		replace tie_count = tie_count + 1 if pct_man`i' == max_pct
		replace has_american = 1 if pct_man`i' == max_pct & bornus`i' == 1
		replace has_foreign = 1 if pct_man`i' == max_pct & bornus`i' == 2
	}

	* Conflicting tie: tied owners disagree on bornus
	gen conflicting_tie = (tie_count > 1 & has_american == 1 & has_foreign == 1)

	* Assign bornus - leave missing only for conflicting ties
	gen majority_bornus = .
	forvalues i = 1/4 {
		replace majority_bornus = bornus`i' if pct_man`i' == max_pct & conflicting_tie == 0
	}

	// For top manager
	replace imm_bus = 1 if majority_bornus == 2 & multi_man == 1
	replace nat_bus = 1 if majority_bornus == 1 & multi_man == 1

	append using `part1'

	replace imm_bus = 1 if fully_immigrant == 1
	replace nat_bus = 1 if fully_american == 1

	count
	// Result: 2,165,680

	save "`cleandir'/sbo_new.dta", replace
