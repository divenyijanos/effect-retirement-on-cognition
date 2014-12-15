
* REPLICATION OF BONSANG ET AL (2012)
*=========================================

/*
Description
- They use 6 waves (1998-2008) of HRS --> panel (unbalanced)
- Fixed-effect analysis with dummies of age (at least x age year old)
- Descriptive graphs:
    - Got significant increase in retirement probability and significant drop in
      cognitive score at ages of eligibility (62 and 66-67)
    - Captures only short-term effect
    - Does not replicate on SHARE, eligibility effect on retirement is less
      straightforward, no meaningful cognition effect
- For IV-estimation: dummies of reaching eligibility age plus 1 (retired for at
  least one year)
    - 51-75 years old
    - Does not take into account the lenght of retirement --> "within average
      effect of about 5 years post retirement"
    - individuals retiring experience a drop in cognitive test score by about 1
      point. This corresponds to about a 10% decrease in cognitive score
      (compared to the sample average score)
    - the effect seems to be higher for men
    - Does not replicate on SHARE, retirement effect is insignificant

*/

clear all
set more off

*local fmt "eps, "
local fmt "png, width(1200)"
global output ../results

#delimit ;
local esttab_opt "
    f replace
    booktabs label collabels(none)
    star(* 0.10 ** 0.05 *** 0.01)
    b(a3) se(a2) gaps
    ";
local ecl_opt "
    eplottype(connected)
    rplottype(rline)
    yline(0, lcolor(black) lwidth(thin))
    ";
#delimit cr

use "../data/derived.dta"
gen retired = 1 - emp_work
label variable retired "Retired"

* Sample
keep if age1 >= 51 & age4 <= 75
*keep if wavepart == 124
encode mergeid, gen(id)
xtset id wave
xtdescribe

/*
* Fixed-effects descriptive analysis á lá Bonsang et al.
*--------------------------------------------------------

* Drop individuals with some missing
foreach var of varlist twr age {
    egen nobs_`var' = count(`var'), by(mergeid)
    drop if nobs_`var' < 3
}

foreach num of numlist 50/75 {
    gen age_above`num' = (int(age) >= `num')
}
foreach var of varlist twr retired {
    xtreg `var' i.age_above*, fe vce(robust)
    parmest, saving(fe_pars, replace)

    preserve
    use fe_pars, clear
    keep if regexm(parm, "1.age")
    gen age = substr(parm, -2, .)
    destring age, replace
    if "`var'" == "twr" {
        local ytitle = "Change in cognitive score"
    }
    if "`var'" == "retired" {
        local ytitle = "Change in retirement probability"
    }
    eclplot estimate min95 max95 age, `ecl_opt' xlabel(50(1)70)
    graph export $output/`var'_fe.`fmt' replace
    rm "fe_pars.dta"
    restore
}


* Fixed-effects descriptive analysis for distance-to-retirement
*---------------------------------------------------------------

foreach dist in ndist edist {
    quietly tab `dist'_mp, gen(`dist'_dum)
    quietly sum `dist'_mp

    foreach num of numlist -10/10 {
        local posnum = `num' + 10
        gen `dist'_atleast`posnum'_m10 = (`dist'_mp >= `num')
    }


    foreach var of varlist twr retired {
        xtreg `var' `dist'_atleast*, fe vce(robust)
        parmest, saving(fe_pars, replace)

        preserve
        use fe_pars, clear
        keep if regexm(parm, "^`dist'")
        gen `dist' = substr(parm, 14, strlen(parm) - strlen("`dist'_atleast_m10"))
        destring `dist', replace
        replace `dist' = `dist' - 10

        if "`var'" == "twr" {
            local ytitle = "Change in cognitive score"
        }
        if "`var'" == "retired" {
            local ytitle = "Change in retirement probability"
        }
        eclplot estimate min95 max95 `dist', `ecl_opt' xlabel(-10(1)10) ///
            xline(0, lcolor(gs6) lpattern(dash))
        graph export $output/`var'_fe_`dist'.`fmt' replace
        rm "fe_pars.dta"
        restore
    }
}
*/

* Fixed-effects regression mimicing Bonsang et al.
*--------------------------------------------------
*foreach var of varlist twr age yrs_in_ret  {
*    egen nobs_`var' = count(`var'), by(mergeid)
*    drop if nobs_`var' < 3
*}

quietly sum twr
gen twr_st = (twr - `r(mean)') / `r(sd)'

gen retired_atleast1 = (yrs_in_ret >= 1)
    replace retired_atleast1 = . if yrs_in_ret == .
eststo ret: xtivreg2 twr_st (retired = nelig_mp eelig_mp) age agesq, ///
    fe cluster(mergeid) savefirst savefprefix(f)
eststo ret1: xtivreg2 twr_st (retired_atleast1 = nelig_mp eelig_mp) age agesq, ///
    fe cluster(mergeid) savefirst savefprefix(f)

esttab ret* using "../text/replication/basic_B.tex", `esttab_opt' ///
    rename(retired "ret" retired_atleast1 "ret") ///
    varlabels(ret "Retired" ///
              _cons "Constant") ///
    alignment(S S) ///
    stats(N widstat, ///
        fmt(%9.0fc 2) layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{S}{@}") ///
        labels(`"Observations"' `"Weak IV F statistic"')) ///
    mtitles("Retirement duration $>$ 0" "Retirement duration $\geq$ 1")
esttab f* using "../text/replication/basic_B_first.tex", `esttab_opt' ///
    alignment(S S) ///
    stats(N r2, ///
        fmt(%9.0fc 4) layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{S}{@}") ///
        labels(`"Observations"' `"Within-\$R^{2}\$"')) ///
    mtitles("Retired" "Retired for at least 1 year")

/*
* Logarithmic specification
foreach var of varlist yrs_in_ret edist_mp ndist_mp {
    gen l_`var' = log(`var' + 1)
}

eststo lret: xtivreg2 twr_st (l_yrs_in_ret = l_ndist_mp l_edist_mp) age agesq, ///
    fe cluster(mergeid) savefirst savefprefix(lf)

esttab lret
esttab lf*
