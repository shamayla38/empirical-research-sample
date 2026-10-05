* 02_clean.do
* Purpose: take the three messy raw CSVs and turn them into two clean, validated .dta files that the analysis script can trust:
*   data/clean/panel.dta  (district-year data for the DiD design)
*   data/clean/cases.dta  (case-level data for the RD design)

* ---------------------------------------------------------------
* A. Clean and Check the district lookup (one row per district).
* ---------------------------------------------------------------

import delimited "data/raw/districts.csv", clear stringcols(_all)
replace district_id = strtrim(district_id)
destring treated, replace
assert !missing(district_id)
assert inlist(treated, 0, 1)
isid district_id
tempfile districts
save `districts'

* ---------------------------------------------------------------
* B. Clean and merge the district-year panel.
* ---------------------------------------------------------------

import delimited "data/raw/district_panel.csv", clear stringcols(_all)

* Cleaning 

replace district_id = strtrim(district_id)
destring year delay_days, replace
count if delay_days == -99
replace delay_days = . if delay_days == -99
misstable summarize delay_days
duplicates report
duplicates drop
assert _N == 320
assert !missing(district_id)
assert inrange(year, 2015, 2022)
isid district_id year

* merge

merge m:1 district_id using `districts'
tabulate _merge
assert _merge == 3
drop _merge


encode district_id, gen(district_num)

* Create the DiD indicator

generate post = year >= 2019
generate did = treated * post
assert inlist(did, 0, 1)
bysort district_id: assert _N == 8
xtset district_num year

* label variable 
label variable delay_days "Average case-processing delay (days)"
label variable did "Treated district after reform"
save "data/clean/panel.dta", replace

* ---------------------------------------------------------------
* C. Clean the case-level RD data.
* ---------------------------------------------------------------


import delimited "data/raw/cases.csv", clear stringcols(_all)
replace case_id = strtrim(case_id)
destring score duration_days, replace

* Cleaning 
count if duration_days == -99
replace duration_days = . if duration_days == -99
misstable summarize duration_days
duplicates report
duplicates drop
assert _N == 1000
assert !missing(case_id)
isid case_id
assert !missing(score)
assert inrange(score, 30, 70)

* Create RD variables

generate centered_score = score - 50
generate eligible = score >= 50
assert inlist(eligible, 0, 1)

* add label
label variable duration_days "Case-processing duration (days)"
save "data/clean/cases.dta", replace
