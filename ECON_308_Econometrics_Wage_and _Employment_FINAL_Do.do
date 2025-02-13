/*ECON 308: Econometrics Fall 2024 Research Paper*/
/*Minimum Wage and Employment*/
/*Caroline Callahan*/

/*Imported the IPUM CPS dataset with data from 2014-2018. This is the post-treatment period.*/
import excel "H:\ECON_308_RP_FINALcps_00007.xlsx", firstrow clear
save "data_2014_2018.dta", replace
describe


/*Imported the IPUM CPS dataset with data from 2008-2012. This is the pre-treatment period.*/
import excel "H:\ECON_308_RP_FINAL_08.13_cps_00009.xlsx", firstrow clear
save "data_2008_2013.dta", replace
describe


/*Imported the IPUM CPS dataset with data from 2013. This is still the pre-treatment period.*/
import excel "H:\ECON_308_RP_FINAL_13_ONLY_v2_cps_00010.xlsx", firstrow clear
save "data_2013.dta", replace
describe


/*The current dataset includes data from all fifty states. Only Arkansas data with STATEFIP code = 5 and Mississippi data with STATEFIP code = 28 was kept; the rest of the data was dropped. The Arkansas and Mississippi data was saved as new subsets*/
preserve
use "data_2014_2018.dta", clear
keep if STATEFIP == 5 | STATEFIP == 28
save "data_2014_2018_subset.dta", replace

preserve
use "data_2008_2013.dta", clear
keep if STATEFIP == 5 | STATEFIP == 28
save "data_2008_2013_subset.dta", replace

preserve
use "data_2013.dta", clear
keep if STATEFIP == 5 | STATEFIP == 28
save "data_2013_subset.dta", replace


/*The 2014-2018 data had an extra household weight variable HFLAG that wasn't necessary to keep, so it was dropped.*/
use "data_2014_2018_subset.dta", clear
drop HFLAG


/*The 2008-2012, 2013, and 2014-2018 data subsets were appended into one subset.*/
preserve
append using "data_2008_2013_subset.dta" "data_2013_subset.dta"
describe
list in 1/10


/*The first control variable, "WORKER_PRODUCT," was created by dividing annual wage and salary income by annual hours worked.*/ 
generate total_hours_year = UHRSWORKT * 52
generate WORKER_PRODUCT = INCWAGE / total_hours_year
list INCWAGE UHRSWORKT total_hours_year WORKER_PRODUCT if missing(WORKER_PRODUCT)
replace WORKER_PRODUCT = 0 if missing(WORKER_PRODUCT)


/*The second control variable, STATE_POP, was created and state population by year data was matched by STATEFIP code and YEAR.*/
generate STATE_POP = .

replace STATE_POP = 2874554 if STATEFIP == 5 & YEAR == 2008
replace STATE_POP = 2896843 if STATEFIP == 5 & YEAR == 2009
replace STATE_POP = 2921998 if STATEFIP == 5 & YEAR == 2010
replace STATE_POP = 2941038 if STATEFIP == 5 & YEAR == 2011
replace STATE_POP = 2952876 if STATEFIP == 5 & YEAR == 2012
replace STATE_POP = 2960459 if STATEFIP == 5 & YEAR == 2013

replace STATE_POP = 2947806 if STATEFIP == 28 & YEAR == 2008
replace STATE_POP = 2958774 if STATEFIP == 28 & YEAR == 2009
replace STATE_POP = 2970615 if STATEFIP == 28 & YEAR == 2010
replace STATE_POP = 2979147 if STATEFIP == 28 & YEAR == 2011
replace STATE_POP = 2984599 if STATEFIP == 28 & YEAR == 2012
replace STATE_POP = 2989839 if STATEFIP == 28 & YEAR == 2013

replace STATE_POP = 2968759 if STATEFIP == 5 & YEAR == 2014
replace STATE_POP = 2979732 if STATEFIP == 5 & YEAR == 2015
replace STATE_POP = 2991815 if STATEFIP == 5 & YEAR == 2016
replace STATE_POP = 3003855 if STATEFIP == 5 & YEAR == 2017
replace STATE_POP = 3012161 if STATEFIP == 5 & YEAR == 2018

replace STATE_POP = 2991892 if STATEFIP == 28 & YEAR == 2014
replace STATE_POP = 2990231 if STATEFIP == 28 & YEAR == 2015
replace STATE_POP = 2990595 if STATEFIP == 28 & YEAR == 2016
replace STATE_POP = 2990674 if STATEFIP == 28 & YEAR == 2017
replace STATE_POP = 2892879 if STATEFIP == 28 & YEAR == 2018


/*The data was reviewed and renamed as "combined_data.dta."*/
describe
list in 1/10
preserve
save "combined_data.dta", replace


/*The dummy variable "period" was created for any year in the pre-treatment period, from 2008-2013.*/
gen period = 0
replace period = 1 if YEAR >=2014


/*Created the dummy variable "treatment" to identify whether the observation was for an individual in Arkansas (the treated group, meaning treat = 1) or an individual in Mississippi (the non-treated group, meaning treat = 0).*/
gen treat = 0
replace treat = 1 if STATEFIP == 5


/*Created a new variable "period_treat" which is the interaction term between the period and treatment dummy variables.*/
gen period_treat = period * treat


/*Created a new dummy variable for the individuals' employment statuses.*/
gen employed = 0
replace employed = 1 if EMPSTAT == 10 | EMPSTAT == 12


/*Created a dummy variable for whether the individual was part of the labor force (meaning they were employed or unemployed; the codes identified came from the IPUM CPS codebook).*/
gen labor_force_indicator = 0
replace labor_force_indicator = 1 if EMPSTAT == 10 | EMPSTAT == 12 | EMPSTAT == 21 | EMPSTAT == 22


/*Used the "employed" and "labor_force_indicator" dummy variables to calculcate the total labor force and total employed by state and year. Then, the total employment percentage was calculated.*/
egen total_labor_force = total(labor_force_indicator), by(STATEFIP YEAR)
egen total_employed = total(employed), by(STATEFIP YEAR)
gen employment_percentage = (total_employed / total_labor_force) * 100


/*Generated the summary statistics table of key outcome and explanatory variables.*/
summarize employment_percentage period treat period_treat WORKER_PRODUCT STATE_POP


/*The difference-in-differences regression was run to identitify the impact of the minimum wage law treatment on employment. The results table was formatted.*/
ssc install outreg2, replace
regress employment_percentage i.period i.treat period_treat WORKER_PRODUCT STATE_POP, cluster(STATEFIP)

/* Used outreg2 to create the final results output table */
outreg2 using "H:/regression_results_table_final.doc", replace ctitle("Difference-in-Differences Regression Results")
    se star(* 0.10 ** 0.05 *** 0.01) r2
	
/*Robustness check: parallel trends assumption pre-treatment trends check using lgraph.*/
ssc install lgraph
collapse (mean) employment_percentage, by(YEAR treat) 
lgraph employment_percentage YEAR, by(treat) xline(2014)














