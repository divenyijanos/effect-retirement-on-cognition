clear all
set more off
local fmt "eps, "
global output ../results

#delimit ;
local esttab_opt " 
    f replace
    booktabs label collabels(none)
    star(* 0.10 ** 0.05 *** 0.01)
    b(3) se(a2) gaps
    ";
#delimit cr

use "../data/derived.dta"
gen retired = 1 - emp_work
label variable retired "Retired"

/*
* Estimate separately for countries
*-----------------------------------
preserve
keep if wave == 1
keep if age >= 50 & age <= 70
keep if jobsit <= 3
keep if worked_at50 == 1 

quietly sum twr
gen twr_st = (twr - `r(mean)') / `r(sd)'

levelsof(countrycode), local(countries)
quietly unique(countrycode)
local ncountries = `r(sum)'
matrix countryregs = J(`ncountries',3,.)
local i = 0
foreach c of local countries {
    local i = `i' + 1
    drop twr_st
    quietly sum twr if countrycode=="`c'"
    gen twr_st = (twr - `r(mean)') / `r(sd)'
    reg twr_st yrs_in_ret age female if countrycode=="`c'"
    matrix countryregs[`i',1] = _b[yrs_in_ret]
    matrix countryregs[`i',2] = _b[yrs_in_ret] - 2*_se[yrs_in_ret]
    matrix countryregs[`i',3] = _b[yrs_in_ret] + 2*_se[yrs_in_ret]
}

matrix list countryregs

tokenize `" `countries' "' /*"technical comment to restore syntax highlighting*/
foreach num of numlist 1/`ncountries' {
    local labellist = "`labellist' r`num'=``num''"
}

disp "`labellist'"

coefplot (matrix(countryregs[,1]), ci((countryregs[,2] countryregs[,3]))), ///
    vertical yline(0) coeflabel(`labellist')
graph export $output/country-coefs.eps, replace

tabstat yrs_in_ret, by(country)

restore
*/

* Panel
*-------

* Descriptive graph

keep if age1 >= 50 & age1 <= 70
keep if jobsit <= 3
keep if worked_at50 == 1 


local cogn twr numeracy

foreach var of varlist `cogn' { 
    if "`var'"=="twr" { 
        local title total word recall 
        }
    if "`var'"=="fluency" { 
        local title fluency
        }
    if "`var'"=="numeracy" { 
        local title numeracy
        }
    
    
    * Sample: worked in wave 1, retirement as absorbing state, and have all observations
    preserve
    keep if wavepart == 124 & hist >= 100  & hist < . & hist != 101
    
    capture qui separate `var', by(hist)
    collapse `var'???, by(country wave)
        #delimit ;
    twoway connected `var'??? wave, 
        by(country, note("") legend(at(11) pos(0)))
        legend(cols(1) textfirst order(- "Working history:" 1 "100" 2 "110" 3 "111"))
        clwidth(thick thick thick) 
        clpattern(. "-" ".")
        msymbol(d O S )
        mfcolor(. white white)
        xlabel(1 2 4) ytitle("mean score on `title'")
        ;
    # delimit cr
    graph export $output/`var'_hist_waves.`fmt' replace 
    restore
    }


** W 1-2 **

preserve

* sample
keep if wavepart == 12 | wavepart == 124
keep if hist == 11 | hist == 111 | hist == 110 | hist == 0
gen ret12 = (hist == 0)

keep if wave == 1

tab ret12

replace ret12 = ret12 * d12_years
lab var ret12 "Years in retirement"
lab var d12_years "Years elapsed"

* dependent variable
foreach var of local cogn {
    quietly sum `var'1
    gen `var'1_sd = (`var'1 - `r(mean)') / `r(sd)'
    quietly sum `var'2
    gen `var'2_sd = (`var'2 - `r(mean)') / `r(sd)'
    gen d12_`var'_sd = `var'2_sd - `var'1_sd

* estimation
    eststo `var'1: ivreg2 d12_`var'_sd (ret12=edist_mp ndist_mp) ///
                                        d12_years
    eststo `var'2: ivreg2 d12_`var'_sd (ret12=edist_mp ndist_mp) ///
                                        d12_years female
    eststo `var'3: xi: ivreg2 d12_`var'_sd (ret12=edist_mp ndist_mp) ///
                                            d12_years female i.country
    eststo `var'4: xi: reg d12_`var'_sd ret12 ///
                                        d12_years female i.country
    eststo `var'5: xi: reg d12_`var'_sd ret12 ///
                                        d12_years female i.country age1

    esttab `var'* using "../text/d12_`var'.tex", `esttab_opt' ///
        alignment(S) ///
        indicate(Country dummies = _Icountry*, labels({Yes} {No})) ///
        stats(N widstat, ///
            fmt(%9.0fc 2) layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{S}{@}") ///
            labels(`"Observations"' `"Weak IV \$F\$ statistic"')) ///
        mtitles("2SLS" "2SLS" "2SLS" "OLS" "OLS")

    eststo clear
}

restore

** W 2-4 **

preserve

* sample
keep if age2 >= 50 & age2 <= 70
keep if jobsit <= 3
keep if worked_at50 == 1 

keep if wavepart == 24 | wavepart == 124
keep if hist == 111 | hist == 11 | hist == 0 | hist == 100
gen ret24 = (hist == 0 | hist == 100)


tab ret24

keep if wave == 2

replace ret24 = ret24 * d24_years
lab var ret24 "Years in retirement"
lab var d24_years "Years elapsed"

* dependent variable
foreach var of local cogn {
    quietly sum `var'2
    gen `var'2_sd = (`var'2 - `r(mean)') / `r(sd)'
    quietly sum `var'4
    gen `var'4_sd = (`var'4 - `r(mean)') / `r(sd)'
    gen d24_`var'_sd = `var'4_sd - `var'2_sd

* estimation
    eststo `var'1: ivreg2 d24_`var'_sd (ret24=edist_mp ndist_mp) ///
                                        d24_years
    eststo `var'2: ivreg2 d24_`var'_sd (ret24=edist_mp ndist_mp) ///
                                        d24_years female
    eststo `var'3: xi: ivreg2 d24_`var'_sd (ret24=edist_mp ndist_mp) ///
                                            d24_years female i.country
    eststo `var'4: xi: reg d24_`var'_sd ret24 ///
                                        d24_years female i.country
    eststo `var'5: xi: reg d24_`var'_sd ret24 ///
                                        d24_years female i.country age1

    esttab `var'* using "../text/d24_`var'.tex", `esttab_opt' ///
        alignment(S) ///
        indicate(Country dummies = _Icountry*, labels({Yes} {No})) ///
        stats(N widstat, ///
            fmt(%9.0fc 2) layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{S}{@}") ///
            labels(`"Observations"' `"Weak IV \$F\$ statistic"')) ///
        mtitles("2SLS" "2SLS" "2SLS" "OLS" "OLS")

    eststo clear
}

restore

** W 1-4 **

* sample
keep if age1 >= 50 & age1 <= 70
keep if jobsit <= 3
keep if worked_at50 == 1 

keep if wavepart == 14 | wavepart == 124
keep if hist == 111 | hist == 101 | hist == 0
gen ret14 = (hist==0)

tab ret14

keep if wave == 1

replace ret14 = ret14 * d14_years
lab var ret14 "Years in retirement"
lab var d14_years "Years elapsed"

* dependent variable
foreach var of local cogn {
    quietly sum `var'1
    gen `var'1_sd = (`var'1 - `r(mean)') / `r(sd)'
    quietly sum `var'4
    gen `var'4_sd = (`var'4 - `r(mean)') / `r(sd)'
    gen d14_`var'_sd = `var'4_sd - `var'1_sd

* estimation
    eststo `var'1: ivreg2 d14_`var'_sd (ret14=edist_mp ndist_mp) ///
                                        d14_years
    eststo `var'2: ivreg2 d14_`var'_sd (ret14=edist_mp ndist_mp) ///
                                        d14_years female
    eststo `var'3: xi: ivreg2 d14_`var'_sd (ret14=edist_mp ndist_mp) ///
                                            d14_years female i.country
    eststo `var'4: xi: reg d14_`var'_sd ret14 ///
                                        d14_years female i.country
    eststo `var'5: xi: reg d14_`var'_sd ret14 ///
                                        d14_years female i.country age1

    esttab `var'* using "../text/d14_`var'.tex", `esttab_opt' ///
        alignment(S) ///
        indicate(Country dummies = _Icountry*, labels({Yes} {No})) ///
        stats(N widstat, ///
            fmt(%9.0fc 2) layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{S}{@}") ///
            labels(`"Observations"' `"Weak IV \$F\$ statistic"')) ///
        mtitles("2SLS" "2SLS" "2SLS" "OLS" "OLS")

    eststo clear
}







