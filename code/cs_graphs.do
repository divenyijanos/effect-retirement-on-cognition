clear all
set more off
local fmt "eps, "
*local fmt "png, width(1200)"
global output ../results

use "../data/derived.dta"
gen retired = 1 - emp_work
label variable retired "Retired"


* Estimate separately for countries, get graph about the coefficients
*---------------------------------------------------------------------
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

* TWR by age for employed and unemployed, wave 1, lowess
*----------------------------------------------------------------
preserve
keep if age1 >= 50 & age1 <= 80
keep if jobsit <= 3
keep if worked_at50 == 1
keep if wave==1

gen byte n=1
collapse twr (sum) n, by(age retired)
keep if n>=20

twoway lowess twr age if retired == 0, mean noweight bw(12) ///
 || lowess twr age if retired == 1, mean noweight bw(12) ///
    legend(order(1 "retired" 2 "employed")) ///
    xtitle("age") ytitle("total word recall (smoothed average)")
graph export $output/emp_notemp_lowess.`fmt' replace

restore

* TWR by age for employed and unemployed, wave 1, for each country
*-------------------------------------------------------------------
preserve
keep if age1 >= 50 & age1 <= 80
keep if jobsit <= 3
keep if worked_at50 == 1
keep if wave==1
drop if country == 19 /* exclude Greece which only in wave 1-2, not in 4 */

gen byte n=1
collapse twr (sum) n, by(age retired country)
keep if n>=10

twoway scatter twr age if retired == 1, by(country) ///
    || scatter twr age if retired == 0, by(country, note("") legend(at(11) pos(0))) ///
    legend(cols(1) order(1 "retired" 2 "employed")) ///
    xtitle("age") ytitle("average total word recall")
graph export $output/emp_notemp.`fmt' replace
