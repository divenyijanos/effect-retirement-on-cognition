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

local cogn twr numeracy fluency


** W 1-2 ****************************

use "../data/derived.dta"

* sample
keep if age1 >= 50 & age1 <= 70
keep if jobsit1 <= 3
keep if worked_at50 == 1

keep if wavepart == 12 | wavepart == 124
drop if hist == 10 | hist == 11
// keep if hist == 11 | hist == 111 | hist == 110 | hist == 0
gen ret12 = (hist == 0 | hist == 1 | hist == 100 | hist == 101)

gen yrs_in_ret_12 = ret12 * d12_years
    replace yrs_in_ret_12 = min(yrs_in_ret, d12_years) if hist == 100 | hist == 101
    replace yrs_in_ret_12 = ret12 * d12_years / 2 if yrs_in_ret == . & (hist == 100 | hist == 101)
lab var yrs_in_ret_12 "Years in retirement"
lab var d12_years "Years elapsed"

keep if wave == 2

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
    eststo `var'1: ivreg2 d12_`var'_sd (yrs_in_ret_12=edist_mp ndist_mp) d12_years, savefirst savefprefix(f12`var'a)
    eststo `var'2: ivreg2 d12_`var'_sd (yrs_in_ret_12=edist_mp ndist_mp) d12_years female, savefirst savefprefix(f12`var'b)
    eststo `var'3: xi: ivreg2 d12_`var'_sd (yrs_in_ret_12=edist_mp ndist_mp) d12_years female i.country, savefirst savefprefix(f12`var'c)

    eststo `var'4: xi: reg d12_`var'_sd yrs_in_ret_12 d12_years female i.country
    eststo `var'5: xi: reg d12_`var'_sd yrs_in_ret_12 d12_years female i.country age

    *restore

    esttab `var'* using "../text/d12_`var'.tex", `esttab_opt' ///
        alignment(S) ///
        indicate(Country dummies = _Icountry*, labels({Yes} {No})) ///
        varlabels(age "Age at first wave" _cons "Constant") ///
        stats(N widstat, ///
            fmt(%9.0fc 2) layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{S}{@}") ///
            labels(`"Observations"' `"Weak IV \$F\$ statistic"')) ///
        mtitles("2SLS" "2SLS" "2SLS" "OLS" "OLS")

    esttab f12`var'* using "../text/d12_`var'_first.tex", `esttab_opt' ///
        alignment(S S S) ///
        indicate(Country dummies = _Icountry*, labels({Yes} {No})) ///
        varlabels(age "Age at first wave" _cons "Constant") ///
        stats(N r2, ///
            fmt(%9.0fc 4) layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{S}{@}") ///
            labels(`"Observations"' `"\$R^{2}\$"'))

    * separately for gender
    eststo `var'f0: xi: ivreg2 d12_`var'_sd (yrs_in_ret_12 = edist_mp ndist_mp) d12_years i.country if female == 0, savefirst savefprefix(f12`var'f0)
    eststo `var'f1: xi: ivreg2 d12_`var'_sd (yrs_in_ret_12 = edist_mp ndist_mp) d12_years i.country if female == 1, savefirst savefprefix(f12`var'f1)

    eststo `var'f0o: xi: reg d12_`var'_sd yrs_in_ret_12 d12_years i.country age if female == 0
    eststo `var'f1o: xi: reg d12_`var'_sd yrs_in_ret_12 d12_years i.country age if female == 1

    esttab `var'f* using "../text/d12_`var'_gender.tex", `esttab_opt' ///
        alignment(S) ///
        indicate(Country dummies = _Icountry*, labels({Yes} {No})) ///
        varlabels(age "Age at first wave" _cons "Constant") ///
        stats(N widstat, ///
            fmt(%9.0fc 2) layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{S}{@}") ///
            labels(`"Observations"' `"Weak IV \$F\$ statistic"')) ///
        mtitles("2SLS, Men" "2SLS, Women" "OLS, Men" "OLS, Women")

    esttab f12`var'f* using "../text/d12_`var'_gender_first.tex", `esttab_opt' ///
        alignment(S S S) ///
        indicate(Country dummies = _Icountry*, labels({Yes} {No})) ///
        varlabels(age "Age at first wave" _cons "Constant") ///
        stats(N r2, ///
            fmt(%9.0fc 4) layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{S}{@}") ///
            labels(`"Observations"' `"\$R^{2}\$"')) ///
        mtitles("Men" "Women")

    eststo clear

}

** W 2-4 ****************************

use "../data/derived.dta", clear

* sample
keep if age2 >= 50 & age2 <= 70
keep if jobsit2 <= 3
keep if worked_at50 == 1

keep if wavepart == 24 | wavepart == 124
drop if hist == 1 | hist == 101
// keep if hist == 111 | hist == 11 | hist == 0 | hist == 100
gen ret24 = (hist == 0 | hist == 100 | hist == 110)

gen yrs_in_ret_24 = ret24 * d24_years
    replace yrs_in_ret_24 = min(yrs_in_ret, d24_years) if hist == 10 | hist == 110
    replace yrs_in_ret_24 = ret24 * d24_years / 2 if yrs_in_ret == . & (hist == 10 | hist == 110)
lab var yrs_in_ret_24 "Years in retirement"
lab var d24_years "Years elapsed"

keep if wave == 4

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
    eststo `var'1: ivreg2 d24_`var'_sd (yrs_in_ret_24 = edist_mp ndist_mp) d24_years, savefirst savefprefix(f24`var'a)
    eststo `var'2: ivreg2 d24_`var'_sd (yrs_in_ret_24 = edist_mp ndist_mp) d24_years female, savefirst savefprefix(f24`var'b)
    eststo `var'3: xi: ivreg2 d24_`var'_sd (yrs_in_ret_24 = edist_mp ndist_mp) d24_years female i.country, savefirst savefprefix(f24`var'c)

    eststo `var'4: xi: reg d24_`var'_sd yrs_in_ret_24 d24_years female i.country
    eststo `var'5: xi: reg d24_`var'_sd yrs_in_ret_24 d24_years female i.country age

    *restore

    esttab `var'* using "../text/d24_`var'.tex", `esttab_opt' ///
        alignment(S) ///
        indicate(Country dummies = _Icountry*, labels({Yes} {No})) ///
        varlabels(age "Age at second wave" _cons "Constant") ///
        stats(N widstat, ///
            fmt(%9.0fc 2) layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{S}{@}") ///
            labels(`"Observations"' `"Weak IV \$F\$ statistic"')) ///
        mtitles("2SLS" "2SLS" "2SLS" "OLS" "OLS")

    esttab f24`var'* using "../text/d24_`var'_first.tex", `esttab_opt' ///
        alignment(S S S) ///
        indicate(Country dummies = _Icountry*, labels({Yes} {No})) ///
        varlabels(age "Age at first wave" _cons "Constant") ///
        stats(N r2, ///
            fmt(%9.0fc 4) layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{S}{@}") ///
            labels(`"Observations"' `"\$R^{2}\$"'))

    * separately for gender
    eststo `var'f0: xi: ivreg2 d24_`var'_sd (yrs_in_ret_24 = edist_mp ndist_mp) d24_years i.country if female == 0, savefirst savefprefix(f24`var'f0)
    eststo `var'f1: xi: ivreg2 d24_`var'_sd (yrs_in_ret_24 = edist_mp ndist_mp) d24_years i.country if female == 1, savefirst savefprefix(f24`var'f1)

    eststo `var'f0o: xi: reg d24_`var'_sd yrs_in_ret_24 d24_years i.country age if female == 0
    eststo `var'f1o: xi: reg d24_`var'_sd yrs_in_ret_24 d24_years i.country age if female == 1

    esttab `var'f* using "../text/d24_`var'_gender.tex", `esttab_opt' ///
        alignment(S) ///
        indicate(Country dummies = _Icountry*, labels({Yes} {No})) ///
        varlabels(age "Age at first wave" _cons "Constant") ///
        stats(N widstat, ///
            fmt(%9.0fc 2) layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{S}{@}") ///
            labels(`"Observations"' `"Weak IV \$F\$ statistic"')) ///
        mtitles("2SLS, Men" "2SLS, Women" "OLS, Men" "OLS, Women")

    esttab f24`var'f* using "../text/d24_`var'_gender_first.tex", `esttab_opt' ///
        alignment(S S S) ///
        indicate(Country dummies = _Icountry*, labels({Yes} {No})) ///
        varlabels(age "Age at first wave" _cons "Constant") ///
        stats(N r2, ///
            fmt(%9.0fc 4) layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{S}{@}") ///
            labels(`"Observations"' `"\$R^{2}\$"')) ///
        mtitles("Men" "Women")

    eststo clear
}


** W 1-4 ****************************

use "../data/derived.dta", clear

* sample
keep if age1 >= 50 & age1 <= 70
keep if jobsit1 <= 3
keep if worked_at50 == 1

keep if wavepart == 14 | wavepart == 124
// keep if hist == 111 | hist == 101 | hist == 0
drop if hist == 1 | hist == 10 | hist == 11 | (hist == 101 & wavepart == 124)
gen ret14 = (hist == 0 | hist == 100 | hist == 110)

gen yrs_in_ret_14 = ret14 * d14_years
    replace yrs_in_ret_14 = min(yrs_in_ret, d14_years) if hist == 100 | hist == 110
    replace yrs_in_ret_14 = ret14 * d14_years / 2 if yrs_in_ret == . & (hist == 100 | hist == 110)
lab var yrs_in_ret_14 "Years in retirement"
lab var d14_years "Years elapsed"

keep if wave == 4

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
    eststo `var'1: ivreg2 d14_`var'_sd (yrs_in_ret_14 = edist_mp ndist_mp) d14_years, savefirst savefprefix(f14`var'a)
    eststo `var'2: ivreg2 d14_`var'_sd (yrs_in_ret_14 = edist_mp ndist_mp) d14_years female, savefirst savefprefix(f14`var'b)
    eststo `var'3: xi: ivreg2 d14_`var'_sd (yrs_in_ret_14 = edist_mp ndist_mp) d14_years female i.country, savefirst savefprefix(f14`var'c)

    eststo `var'4: xi: reg d14_`var'_sd yrs_in_ret_14 d14_years female i.country
    eststo `var'5: xi: reg d14_`var'_sd yrs_in_ret_14 d14_years female i.country age

    * restore

    esttab `var'* using "../text/d14_`var'.tex", `esttab_opt' ///
        alignment(S) ///
        indicate(Country dummies = _Icountry*, labels({Yes} {No})) ///
        varlabels(age "Age at first wave" _cons "Constant") ///
        stats(N widstat, ///
            fmt(%9.0fc 2) layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{S}{@}") ///
            labels(`"Observations"' `"Weak IV \$F\$ statistic"')) ///
        mtitles("2SLS" "2SLS" "2SLS" "OLS" "OLS")

    esttab f14`var'* using "../text/d14_`var'_first.tex", `esttab_opt' ///
        alignment(S S S) ///
        indicate(Country dummies = _Icountry*, labels({Yes} {No})) ///
        varlabels(age "Age at first wave" _cons "Constant") ///
        stats(N r2, ///
            fmt(%9.0fc 4) layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{S}{@}") ///
            labels(`"Observations"' `"\$R^{2}\$"'))


	* separately for gender
    eststo `var'f0: xi: ivreg2 d14_`var'_sd (yrs_in_ret_14 = edist_mp ndist_mp) d14_years i.country if female == 0, savefirst savefprefix(f14`var'f0)
    eststo `var'f1: xi: ivreg2 d14_`var'_sd (yrs_in_ret_14 = edist_mp ndist_mp) d14_years i.country if female == 1, savefirst savefprefix(f14`var'f1)

    eststo `var'f0o: xi: reg d14_`var'_sd yrs_in_ret_14 d14_years i.country age if female == 0
    eststo `var'f1o: xi: reg d14_`var'_sd yrs_in_ret_14 d14_years i.country age if female == 1

    esttab `var'f* using "../text/d14_`var'_gender.tex", `esttab_opt' ///
        alignment(S) ///
        indicate(Country dummies = _Icountry*, labels({Yes} {No})) ///
        varlabels(age "Age at first wave" _cons "Constant") ///
        stats(N widstat, ///
            fmt(%9.0fc 2) layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{S}{@}") ///
            labels(`"Observations"' `"Weak IV \$F\$ statistic"')) ///
        mtitles("2SLS, Men" "2SLS, Women" "OLS, Men" "OLS, Women")

    esttab f14`var'f* using "../text/d14_`var'_gender_first.tex", `esttab_opt' ///
        alignment(S S S) ///
        indicate(Country dummies = _Icountry*, labels({Yes} {No})) ///
        varlabels(age "Age at first wave" _cons "Constant") ///
        stats(N r2, ///
            fmt(%9.0fc 4) layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{S}{@}") ///
            labels(`"Observations"' `"\$R^{2}\$"')) ///
        mtitles("Men" "Women")

}
