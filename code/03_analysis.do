* 03_analysis.do
* Purpose: run the two regressions (DiD and RD), export three LaTeX table
* fragments, and export two small CSVs that R will use to draw the figures.

* ---------------------------------------------------------------
* A. Summary-statistics table, in two panels (district panel, cases).
* ---------------------------------------------------------------

* Panel A: district-year panel, delay outcome and reform status.
use "data/clean/panel.dta", clear
label variable delay_days "Case-processing delay (days)"
label variable treated "Reform district"
estpost summarize delay_days treated
esttab using "output/tables/summary_panelA.tex", replace booktabs ///
    cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(2)) max(fmt(2))") ///
    label nonumber nomtitles noobs ///
    collabels("N" "Mean" "SD" "Min" "Max")

* Panel B: individual cases, duration outcome, score, and eligibility.
use "data/clean/cases.dta", clear
label variable duration_days "Case-processing duration (days)"
label variable score "Priority score"
label variable eligible "Eligible for fast-track processing"
estpost summarize duration_days score eligible
esttab using "output/tables/summary_panelB.tex", replace booktabs ///
    cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(2)) max(fmt(2))") ///
    label nonumber nomtitles noobs ///
    collabels("N" "Mean" "SD" "Min" "Max")

* ---------------------------------------------------------------
* B. DiD regression and its table.
* ---------------------------------------------------------------

use "data/clean/panel.dta", clear
regress delay_days did i.district_num i.year, vce(cluster district_num)
generate did_sample = e(sample)
estadd local distFE "Yes"
estadd local yearFE "Yes"
estimates store did_model

* Export Results: 
esttab did_model using "output/tables/did.tex", replace booktabs ///
    keep(did) coeflabels(did "Reform district $\times$ Post-reform") ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    stats(distFE yearFE N N_clust, fmt(0 0 0 0) ///
        labels("District fixed effects" "Year fixed effects" "Observations" "District clusters")) ///
    nonumber nomtitles collabels(none) ///
    prehead("{" "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" ///
        "\begin{tabular}{lc}" "\toprule" " & (1)\\" "Dependent variable: & Delay (days)\\")


preserve
    keep if did_sample
    collapse (mean) mean_delay=delay_days (count) n=delay_days, by(treated year)
    export delimited "output/plot_data/did_trends.csv", replace
restore

* ---------------------------------------------------------------
* C. RD regression, table, and plotting data.
* ---------------------------------------------------------------

use "data/clean/cases.dta", clear
regress duration_days i.eligible##c.centered_score ///
    if abs(centered_score) <= 10, vce(robust)
generate rd_sample = e(sample)
estadd local bandwidth "10"
estadd local polyorder "Local linear"
estadd local sepslopes "Yes"
estimates store rd_model
predict fitted_duration if rd_sample, xb

* Export Results:
esttab rd_model using "output/tables/rd.tex", replace booktabs ///
    keep(1.eligible) coeflabels(1.eligible "Fast-track eligibility") ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    stats(bandwidth polyorder sepslopes N, fmt(0 0 0 0) ///
        labels("Bandwidth" "Polynomial order" "Separate slopes across cutoff" "Observations")) ///
    nonumber nomtitles collabels(none) ///
    prehead("{" "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" ///
        "\begin{tabular}{lc}" "\toprule" " & (1)\\" "Dependent variable: & Duration (days)\\")

preserve
    keep if rd_sample
    generate bin = floor(centered_score / 2)
    collapse (mean) score duration_days fitted_duration ///
        (count) n=duration_days, by(eligible bin)
    sort eligible score
    export delimited "output/plot_data/rd_bins.csv", replace
	
restore
