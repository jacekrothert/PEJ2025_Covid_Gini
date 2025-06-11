*********************************************
*Importing dta file 
*********************************************
clear all

*ssc install estout, replace /* optional, for using esttab to export tables into a .tex file */

cd  "G:\My Drive\research\cov19\05_ShortELVersion\PEJ\replication\" /* path to the folder where all files are stored */


use LR_PEJ_dataset_for_replication.dta



**************************************************************
* Organizing data and establishing as panel data
**************************************************************
encode code_borders, gen(panel_id)
sort panel_id date_day
xtset panel_id date_day 
**************************************************************



**************************************************************
* Tracking days until election
**************************************************************
gen days_to_election = election_date - date_day
gen days_to_election_ = election_date - date_day
replace days_to_election = 0 if missing(days_to_election)
replace days_to_election = 0 if days_to_election < 0
foreach num of numlist 15 30 60 90 180 360 {
	qui gen election_`num' = 0
	qui replace election_`num' = 1 if days_to_election < `num'
}
**************************************************************



**************************************************************
* Create weekly dummies
**************************************************************
qui gen time_ = date_day - 21914
foreach num of numlist 2/5 {
qui gen time_`num' = time_^`num'
}
qui gen week = floor(date_day/7)
**************************************************************



* history of similar outbreaks
qui gen sars = 0
qui replace sars = 1 if MERS > 0
qui replace sars = 1 if H7N9 > 0
qui replace sars = 1 if H7N4 > 0

* new cases
qui gen y_temp  = log(total_cases+1)
qui gen y = (y_temp + l.y_temp + l2.y_temp  + l3.y_temp  + l4.y_temp  + l5.y_temp  + l6.y_temp)/7


* reproduction rate
qui rename reproduction_rate rrate_temp
qui gen rrate = (rrate_temp + l.rrate_temp + l2.rrate_temp+ l3.rrate_temp + l4.rrate_temp+ l5.rrate_temp + l6.rrate_temp)/7
qui gen log_rrate = log(rrate)

* policy
qui gen policy_temp = stringencyindex + 1
qui gen str = (policy_temp + l.policy_temp + l2.policy_temp  + l3.policy_temp  + l4.policy_temp  + l5.policy_temp  + l6.policy_temp)/7
qui gen log_str = log(str)

* drop temporary stuff
qui drop policy_temp rrate_temp

* differences and lags
qui gen d_y = d.y			/* growth rate of total cases */
qui gen d_str = d.str
qui gen d_log_str = d.log_str
qui gen lag_dy = l.d_y
qui gen lag_rrate = l.rrate
qui gen lag_log_rrate = l.log_rrate

* inequality
qui gen log_gini_disp = log(gini_disp)
qui gen log_gini_mkt = log(gini_mkt)
qui gen redistribution = gini_mkt - gini_disp
qui gen log_redistribution = log_gini_mkt - log_gini_disp 

* income per capita
qui gen inc     = GDP
qui gen log_inc = log(GDP)

* under-reporting
qui gen cr = log(CaseRatio)




*****************************************************************************************
* 									REPLICATE FIGURE 1
*****************************************************************************************
twoway (tsline stringencyindex if code_owid == "BEL", lcolor(blue) lwidth(thick))  ///
       (tsline stringencyindex if code_owid == "CHE", lcolor(black) lwidth(thick) lpattern(dash)) ///
       , legend(label(1 "Belgium") label(2 "Switzerland")  ///
               position(6) cols(2)) ///
       xtitle("Time") ///
       ytitle("Stringency Index") 
*****************************************************************************************



*****************************************************************************************
* 									REPLICATE FIGURE 2 - left
*****************************************************************************************
twoway (scatter cr log_inc if date_day == 21975, msize(tiny) mlab(code_owid) mlabpos(12)) ///
       (lfit cr log_inc if date_day == 21975, lcolor(red)) , ///
       ytitle("Underreporting") xtitle("log(GDP per capita)") ///
       legend(off)
*****************************************************************************************



*****************************************************************************************
* 									REPLICATE FIGURE 2 - right
*****************************************************************************************
twoway (scatter cr log_redistribution if date_day == 21975, msize(tiny) mlab(code_owid) mlabpos(12)) ///
       (lfit cr log_redistribution if date_day == 21975, lcolor(red)) , ///
       ytitle("Underreporting") xtitle("redistribution") ///
       legend(off)
*****************************************************************************************





	   

local varlista_pol = "log_str d_log_str"
local varlista_out = "d_y log_rrate"
local varlista_oth = "inc log_inc gini_disp gini_mkt log_gini_disp log_gini_mkt redistribution log_redistribution gov_eff fiscal_16 ratecut_16 macrofin_16"

foreach var of varlist `varlista_pol' {
egen temp_ = sd(`var')
egen temp2_ = mean(`var')
qui replace `var' = (`var' - temp2_) / temp_
qui drop temp_ temp2_
}


foreach var of varlist `varlista_out' {
egen temp_ = sd(`var')
egen temp2_ = mean(`var')
qui replace `var' = (`var' - temp2_) / temp_
qui drop temp_ temp2_
}


foreach var of varlist `varlista_oth' {
egen temp_ = sd(`var')
egen temp2_ = mean(`var')
qui replace `var' = (`var' - temp2_) / temp_
qui drop temp_ temp2_
summarize `var'
}



qui gen policy      = d_log_str
qui gen lag_policy  = l.d_log_str
qui gen outbreak    = l.log_rrate
qui gen income      = log_inc
qui gen ineq_disp   = gini_disp
qui gen ineq_mkt    = gini_mkt
qui gen inc_redist  = redistribution



* rename variables for convenience
************************************************************************************************************************
local file_name = "results_bench.xlsx"
qui rename outbreak covid
qui rename fiscal_16 fiscal
lab var fiscal "fiscal"
qui rename ratecut_16 ratecut
lab var ratecut "ratecut"
lab var gov_eff "gov_eff"
************************************************************************************************************************


************************************************************************************************************************
* regressions for Table 1
************************************************************************************************************************
xtreg policy lag_policy covid c.covid#c.income c.covid#i.sars c.covid#i.election_360 c.covid#c.ineq_mkt, fe vce(cluster code_borders)
estimates store m1_fe

xtreg policy lag_policy covid c.covid#c.income c.covid#i.sars c.covid#i.election_360 c.covid#c.ineq_disp, fe vce(cluster code_borders)
estimates store m2_fe

xtreg policy lag_policy covid c.covid#c.income c.covid#i.sars c.covid#i.election_360 c.covid#c.redistribution, fe vce(cluster code_borders)
estimates store m3_fe

xtreg policy lag_policy covid c.covid#c.income c.covid#i.sars c.covid#i.election_360 c.covid#c.redistribution c.covid#c.gov_eff, fe vce(cluster code_borders)
estimates store m4_fe

xtreg policy lag_policy covid c.covid#c.income c.covid#i.sars c.covid#i.election_360 c.covid#c.redistribution c.covid#c.gov_eff c.covid#c.fiscal, fe vce(cluster code_borders)
estimates store m5_fe

xtreg policy lag_policy covid c.covid#c.income c.covid#i.sars c.covid#i.election_360 c.covid#c.redistribution c.covid#c.gov_eff c.covid#c.ratecut, fe vce(cluster code_borders)
estimates store m6_fe

xtreg policy lag_policy covid c.covid#c.income c.covid#i.sars c.covid#i.election_360 c.covid#c.redistribution c.covid#c.gov_eff c.covid#c.fiscal c.covid#c.ratecut, fe vce(cluster code_borders)
estimates store m7_fe
************************************************************************************************************************



************************************************************************************************************************
* 									EXPORT TABLE 1 INTO A .TEX FILE
************************************************************************************************************************
esttab m1_fe m2_fe m3_fe m4_fe m5_fe m6_fe m7_fe using PEJ_results_cluster.tex, ///
    label replace ///
    title(Dependent variable is dstrit) ///
    cells(b(star fmt(3)) t(par fmt(1))) /// coefficients to 3 decimals, t-stats to 1 decimal
    stats(r2_w r2_b r2_o N N_g, ///
    fmt(3 3 3 0 0) /// specifying format for each statistic
    labels("R-squared (within)" "R-squared (between)" "R-squared (overall)" "Observations" "Countries")) ///
    addnote("* $p<0.10$, ** $p<0.05$, *** $p<0.01$")
************************************************************************************************************************	

	
	

	


********************************************************************************	
* 									ROBUSTNESS (TABLE 2)
********************************************************************************		
	

	
	
	

*					HAUSMANN TEST FOR FIXED VS. RANDOM EFFECTS
********************************************************************************	
* Table 2, column (5)
xtreg policy lag_policy covid c.covid#c.income c.covid#i.sars c.covid#i.election_360 c.covid#c.redistribution c.covid#c.gov_eff c.covid#c.fiscal c.covid#c.ratecut, fe
est store hman_fe
* Table 2, column (6)
xtreg policy lag_policy covid c.covid#c.income c.covid#i.sars c.covid#i.election_360 c.covid#c.redistribution c.covid#c.gov_eff c.covid#c.fiscal c.covid#c.ratecut, re
est store hman_re	
hausman hman_fe hman_re, sigmamore


* set benchmark
********************************************************************************	
qui replace policy      = d_log_str
qui replace lag_policy  = l.policy
qui replace covid    	= l.log_rrate
qui replace inc_redist  = redistribution


* log redistribution - Table 2, column (1)
********************************************************************************	
qui replace redistribution = log_redistribution	
xtreg policy lag_policy covid c.covid#c.income c.covid#i.sars c.covid#i.election_360 c.covid#c.redistribution c.covid#c.gov_eff c.covid#c.fiscal c.covid#c.ratecut, fe vce(cluster code_borders)
estimates store rob1	


* log-level of stringency - Table 2, column  (2)
********************************************************************************	
qui replace redistribution = inc_redist  
qui replace policy      = log_str
qui replace lag_policy  = l.policy
xtreg policy lag_policy covid c.covid#c.income c.covid#i.sars c.covid#i.election_360 c.covid#c.redistribution c.covid#c.gov_eff c.covid#c.fiscal c.covid#c.ratecut, fe vce(cluster code_borders)
estimates store rob2	


* weekly fixed effects - Table 2, column  (3)
********************************************************************************	
qui replace policy      = d_log_str
qui replace lag_policy  = l.policy
xtreg policy lag_policy covid c.covid#c.income c.covid#i.sars c.covid#i.election_360 c.covid#c.redistribution c.covid#c.gov_eff c.covid#c.fiscal c.covid#c.ratecut i.week, fe vce(cluster code_borders)
estimates store rob3	
qui replace covid    = l.log_rrate

	
* growth rate of new cases - Table 2, column  (4)
********************************************************************************	
qui replace policy      = d_log_str
qui replace lag_policy  = l.policy
qui replace covid    = l.d_y
xtreg policy lag_policy covid c.covid#c.income c.covid#i.sars c.covid#i.election_360 c.covid#c.redistribution c.covid#c.gov_eff c.covid#c.fiscal c.covid#c.ratecut, fe vce(cluster code_borders)
estimates store rob4	
qui replace covid    = l.log_rrate

	
* Export TABLE 2 into a .tex file
************************************************************************************
esttab rob1 rob2 rob3 rob4 hman_fe hman_re using PEJ_results_robust.tex, ///
    label replace ///
    title(Dependent variable is dstrit) ///
    cells(b(star fmt(3)) t(par fmt(1))) /// coefficients to 3 decimals, t-stats to 1 decimal
    stats(r2_w r2_b r2_o N N_g, ///
    fmt(3 3 3 0 0) /// specifying format for each statistic
    labels("R-squared (within)" "R-squared (between)" "R-squared (overall)" "Observations" "Countries")) ///
    addnote("* $p<0.10$, ** $p<0.05$, *** $p<0.01$")
************************************************************************************	
		
	
	
