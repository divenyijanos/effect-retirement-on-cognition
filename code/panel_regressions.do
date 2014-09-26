clear all
set more off
global output ../results

#delimit ;
local esttab_opt " 
    f replace
    booktabs label collabels(none)
    star(* 0.10 ** 0.05 *** 0.01)
    b(3) se(a2) gaps
    ";
#delimit cr

local cogn twr numeracy


** W 1-2 ****************************

use "../data/derived.dta"

* sample
keep if age1 >= 50 & age1 <= 70
keep if jobsit <= 3
keep if worked_at50 == 1 

keep if wavepart == 12 | wavepart == 124
keep if hist == 11 | hist == 111 | hist == 110 | hist == 0
gen ret12 = (hist == 0)

keep if wave == 1

tab ret12

replace ret12 = ret12 * d12_years
lab var ret12 "Years in retirement"
lab var d12_years "Years elapsed"

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

* dependent variable
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

    preserve

    drop `var'*_sd d12_`var'_sd ret12
    keep if yrs_in_ret == edist_mp | yrs_in_ret == ndist_mp | (yrs_in_ret==0 & edist_mp<0)
    gen ret12 = (hist == 0) 
    tab ret12
    replace ret12 = ret12 * d12_years
    lab var ret12 "Years in retirement"

    quietly sum `var'1
    gen `var'1_sd = (`var'1 - `r(mean)') / `r(sd)'
    quietly sum `var'2
    gen `var'2_sd = (`var'2 - `r(mean)') / `r(sd)'
    gen d12_`var'_sd = `var'2_sd - `var'1_sd

    eststo `var'4: xi: reg d12_`var'_sd ret12 ///
                                        d12_years female i.country
    eststo `var'5: xi: reg d12_`var'_sd ret12 ///
                                        d12_years female i.country age

    restore

    esttab `var'* using "../text/d12_`var'.tex", `esttab_opt' ///
        alignment(S) ///
        indicate(Country dummies = _Icountry*, labels({Yes} {No})) ///
        varlabels(age "Age at first wave" _cons "Constant") ///
        stats(N widstat, ///
            fmt(%9.0fc 2) layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{S}{@}") ///
            labels(`"Observations"' `"Weak IV \$F\$ statistic"')) ///
        mtitles("2SLS" "2SLS" "2SLS" "OLS" "OLS")

    eststo clear
}

** W 2-4 ****************************

use "../data/derived.dta", clear

* sample
keep if age2 >= 50 & age2 <= 70
keep if jobsit <= 3
keep if worked_at50 == 1 

keep if wavepart == 24 | wavepart == 124
keep if hist == 111 | hist == 11 | hist == 0 | hist == 100
gen ret24 = (hist == 0 | hist == 100)

keep if wave == 2

tab ret24

replace ret24 = ret24 * d24_years
lab var ret24 "Years in retirement"
lab var d24_years "Years elapsed"

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

* dependent variable
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
    
    preserve

    drop `var'*_sd d24_`var'_sd ret24
    keep if yrs_in_ret == edist_mp | yrs_in_ret == ndist_mp | (yrs_in_ret==0 & edist_mp<0)
    gen ret24 = (hist == 0 | hist == 100) 
    tab ret24
    replace ret24 = ret24 * d24_years
    lab var ret24 "Years in retirement"

    quietly sum `var'2
    gen `var'2_sd = (`var'2 - `r(mean)') / `r(sd)'
    quietly sum `var'4
    gen `var'4_sd = (`var'4 - `r(mean)') / `r(sd)'
    gen d24_`var'_sd = `var'4_sd - `var'2_sd

    eststo `var'4: xi: reg d24_`var'_sd ret24 ///
                                        d24_years female i.country
    eststo `var'5: xi: reg d24_`var'_sd ret24 ///
                                        d24_years female i.country age

    restore

    esttab `var'* using "../text/d24_`var'.tex", `esttab_opt' ///
        alignment(S) ///
        indicate(Country dummies = _Icountry*, labels({Yes} {No})) ///
        varlabels(age "Age at second wave" _cons "Constant") ///
        stats(N widstat, ///
            fmt(%9.0fc 2) layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{S}{@}") ///
            labels(`"Observations"' `"Weak IV \$F\$ statistic"')) ///
        mtitles("2SLS" "2SLS" "2SLS" "OLS" "OLS")

    eststo clear
}


** W 1-4 ****************************

use "../data/derived.dta", clear

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

* dependent variable
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

    preserve

    drop `var'*_sd d14_`var'_sd ret14
    keep if yrs_in_ret == edist_mp | yrs_in_ret == ndist_mp | (yrs_in_ret==0 & edist_mp<0)
    gen ret14 = (hist == 0) 
    tab ret14
    replace ret14 = ret14 * d14_years
    lab var ret14 "Years in retirement"

    quietly sum `var'1
    gen `var'1_sd = (`var'1 - `r(mean)') / `r(sd)'
    quietly sum `var'4
    gen `var'4_sd = (`var'4 - `r(mean)') / `r(sd)'
    gen d14_`var'_sd = `var'4_sd - `var'1_sd

    eststo `var'4: xi: reg d14_`var'_sd ret14 ///
                                        d14_years female i.country
    eststo `var'5: xi: reg d14_`var'_sd ret14 ///
                                        d14_years female i.country age

    restore

    esttab `var'* using "../text/d14_`var'.tex", `esttab_opt' ///
        alignment(S) ///
        indicate(Country dummies = _Icountry*, labels({Yes} {No})) ///
        varlabels(age "Age at first wave" _cons "Constant") ///
        stats(N widstat, ///
            fmt(%9.0fc 2) layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{S}{@}") ///
            labels(`"Observations"' `"Weak IV \$F\$ statistic"')) ///
        mtitles("2SLS" "2SLS" "2SLS" "OLS" "OLS")

    eststo clear
}

