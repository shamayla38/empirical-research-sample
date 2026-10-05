* _master.do
* Purpose: this is the ONLY Stata file you open and run by hand. It sets the
* project folder, creates the output folders, and then calls the cleaning
* and analysis scripts in order, with a log recording everything that happens.


version 15
clear all
set more off

* Before running, set Stata's working directory to the repository folder.
global root "`c(pwd)'"
cd "$root"

capture mkdir "data/clean"
capture mkdir "output"
capture mkdir "output/tables"
capture mkdir "output/figures"
capture mkdir "output/plot_data"
capture mkdir "output/logs"

capture log close
log using "output/logs/stata_run.log", text replace


do "code/02_clean.do"
do "code/03_analysis.do"

log close
display "Stata stages finished. Run R figures next."
