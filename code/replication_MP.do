
* REPLICATION OF MAZZONNA-PERACCHI (2012)
*=========================================

/*
Description
- They use the 2004 wave of SHARE  --> CS analysis
- Measure cognition by various ways (delayed and immediate recall separately)
- Retired: currently not working for pay
- Persons aged 60-64

*/

clear all
set more off

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


keep if wave == 1

* REPLICATION OF RW-METHOD WITH TWO IVS
*---------------------------------------
preserve
keep if age >= 60 & age < 65 /*60-64 years old*/
quietly sum yrs_in_ret
local yrs = trim("`: display %9.1f r(mean) '")
tempname yrs6064
file open `yrs6064' using "../text/replication/retirement-years_60-64.txt", write replace
file write `yrs6064' `" `yrs' "' /*"technical comment*/
file close `yrs6064'

quietly sum twr
gen twr_st = (twr - `r(mean)') / `r(sd)'
quietly sum numeracy
gen numeracy_st = (numeracy - `r(mean)') / `r(sd)'

* RW method with MP IV as well (variability of eligibility within country)
eststo RW: ivreg2 twr_st (retired = eelig_rw nelig_rw), ///
    savefirst savefprefix(fRW)

eststo MP: ivreg2 twr_st (retired = eelig_mp nelig_mp), ///
    savefirst savefprefix(fMP)

esttab fRW* fMP* using "../text/replication/basicIV_first_MP-RW.tex", `esttab_opt' ///
    alignment(S S) ///
    rename(eelig_mp "eelig" eelig_rw "eelig" nelig_mp "nelig" nelig_rw "nelig") ///
    varlabels(eelig "Eligible for early benefits" ///
              nelig "Eligible for full benefits" ///
              _cons "Constant") ///
    stats(N r2_a, ///
        fmt(%9.0fc 4) layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{S}{@}") ///
        labels(`"Observations"' `"adjusted \$R^{2}\$"')) ///
    mtitles("\citeasnoun{RW}" "\citeasnoun{MP}")

esttab RW MP using "../text/replication/basicIV_MP-RW.tex", `esttab_opt' ///
    alignment(S S) ///
    stats(N, fmt(%9.0fc) layout("\multicolumn{1}{c}{@}") labels(`"Observations"')) ///
    mtitles("\citeasnoun{RW}" "\citeasnoun{MP}")

eststo clear

* gender differences in cognitive scores (controlling for age) in RW sample
reg twr_st female i.age
local twr_female = trim("`: display %9.2f _b[female]'")
tempname twrdiff_rw
file open `twrdiff_rw' using "../text/replication/gender-diff-twr-RW.txt", write replace
file write `twrdiff_rw' `" `twr_female' "' /*"*/
file close `twrdiff_rw'

reg numeracy_st female i.age
local num_female = trim("`: display %9.2f _b[female]'")
tempname numdiff_rw
file open `numdiff_rw' using "../text/replication/gender-diff-num-RW.txt", write replace
file write `numdiff_rw' `" `num_female' "' /*"*/
file close `numdiff_rw'


* REPLICATION OF MP-METHOD
*--------------------------
* Gradually moving from RW

* using years instead of dummy
eststo: ivreg2 twr_st (yrs_in_ret = edist_mp ndist_mp), savefirst savefprefix(fy)

* extend to age range 50-70
restore
keep if age >= 50 & age <= 70
quietly sum yrs_in_ret
local yrs = trim("`: display %9.1f r(mean) '")
tempname yrs5070
file open `yrs5070' using "../text/replication/retirement-years_50-70.txt", write replace
file write `yrs5070'
file write `yrs5070' `" `yrs' "' /*"*/
file close `yrs5070'

quietly sum twr
gen twr_st = (twr - `r(mean)') / `r(sd)'

eststo: ivreg2 twr_st (yrs_in_ret = edist_mp ndist_mp), savefirst savefprefix(fyr)

* controlling for worked at 50
drop twr_st
keep if jobsit <= 3
keep if worked_at50 == 1
sum yrs_in_ret

quietly sum twr
gen twr_st = (twr - `r(mean)') / `r(sd)'
quietly sum numeracy
gen numeracy_st = (numeracy - `r(mean)') / `r(sd)'


* gender differences in cognitive scores (controlling for age) in MP sample
reg twr_st female i.age
local twr_female = trim("`: display %9.2f _b[female]'")
tempname twrdiff_mp
file open `twrdiff_mp' using "../text/replication/gender-diff-twr-MP.txt", write replace
file write `twrdiff_mp' `" `twr_female' "' /*"*/
file close `twrdiff_mp'

reg numeracy_st female i.age
local num_female = trim("`: display %9.2f _b[female]'")
tempname numdiff_mp
file open `numdiff_mp' using "../text/replication/gender-diff-num-MP.txt", write replace
file write `numdiff_mp' `" `num_female' "' /*"*/
file close `numdiff_mp'

eststo: ivreg2 twr_st (yrs_in_ret = edist_mp ndist_mp), savefirst savefprefix(fyrb)

* control for age
eststo: ivreg2 twr_st (yrs_in_ret = edist_mp ndist_mp) age, ///
    savefirst savefprefix(fyrba)

* Correlation of eligibility ages and years of education
quietly correlate early_mp yeduc
local earlyc = trim("`: display %9.2f r(rho)'")
tempname earlycorr
file open `earlycorr' using "../text/replication/correlation-early-yeduc.txt", write replace
file write `earlycorr' `" `earlyc' "' /*"*/
file close `earlycorr'

quietly correlate normal_mp yeduc
local normalc = trim("`: display %9.2f r(rho)'")
tempname normalcorr
file open `normalcorr' using "../text/replication/correlation-normal-yeduc.txt", write replace
file write `normalcorr' `" `normalc' "' /*"*/
file close `normalcorr'


* control for country
eststo: xi: ivreg2 twr_st (yrs_in_ret = edist_mp ndist_mp) age i.country, ///
    savefirst savefprefix(fyrbac)

esttab using "../text/replication/RW_to_MP.tex", `esttab_opt' ///
    alignment(S) indicate(Country dummies = _Icountry*, labels({Yes} {No})) ///
    stats(N widstat, ///
        fmt(%9.0fc 2) layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{S}{@}") ///
        labels(`"Observations"' `"Weak IV \$F\$ statistic"')) ///
    mtitles("aged 60-64" "aged 50-70" "+ worked at 50" "+ age" "+ country")

esttab fy* using "../text/replication/RW_to_MP_first.tex", `esttab_opt' ///
    alignment(S) indicate(Country dummies = _Icountry*, labels({Yes} {No})) ///
    stats(N r2_a, ///
        fmt(%9.0fc 4) layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{S}{@}") ///
        labels(`"Observations"' `"adjusted \$R^{2}\$"')) ///
    mtitles("aged 60-64" "aged 50-70" "+ worked at 50" "+ age" "+ country")

eststo clear


* Compare control for gender for twr vs. numeracy
* (numeracy should be more negative if gender differences affect the coefficient)
eststo: xi: ivreg2 twr_st (yrs_in_ret = ndist_mp edist_mp) age i.country
eststo: xi: ivreg2 twr_st (yrs_in_ret = ndist_mp edist_mp) age female i.country
eststo: xi: ivreg2 numeracy_st (yrs_in_ret = ndist_mp edist_mp) age i.country
eststo: xi: ivreg2 numeracy_st (yrs_in_ret = ndist_mp edist_mp) age female i.country

esttab using "../text/replication/MP_gender_control.tex", `esttab_opt' ///
    alignment(S) indicate(Country dummies = _Icountry*, labels({Yes} {No})) ///
    stats(N widstat, ///
        fmt(%9.0fc 2) layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{S}{@}") ///
        labels(`"Observations"' `"Weak IV \$F\$ statistic"')) ///
    mtitles("TWR" "TWR" "numeracy" "numeracy")

eststo clear

* Estimate separate equations
eststo: xi: ivreg2 twr_st (yrs_in_ret = ndist_mp edist_mp) age i.country if female == 0
eststo: xi: ivreg2 twr_st (yrs_in_ret = ndist_mp edist_mp) age i.country if female == 1
eststo: xi: ivreg2 numeracy_st (yrs_in_ret = ndist_mp edist_mp) age i.country if female == 0
eststo: xi: ivreg2 numeracy_st (yrs_in_ret = ndist_mp edist_mp) age i.country if female == 1

esttab using "../text/replication/MP_separate_gender.tex", `esttab_opt' ///
    alignment(S) indicate(Country dummies = _Icountry*, labels({Yes} {No})) ///
    stats(N widstat, ///
        fmt(%9.0fc 2) layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{S}{@}") ///
        labels(`"Observations"' `"Weak IV \$F\$ statistic"')) ///
    mtitles("TWR, men" "TWR, women" "numeracy, men" "numeracy, women")

eststo clear


* On FWR, separately for genders
eststo fwrfols: xi: reg fwr yrs_in_ret age i.country if female == 0
eststo fwrmols: xi: reg fwr yrs_in_ret age i.country if female == 1

eststo fwro: xi: ivreg2 fwr (yrs_in_ret = ndist_mp edist_mp) age i.country, ///
    savefirst savefprefix(fwrfio)

eststo fwrm: xi: ivreg2 fwr (yrs_in_ret = ndist_mp edist_mp) age i.country if female == 0, ///
    savefirst savefprefix(fwrfim)

eststo fwrf: xi: ivreg2 fwr (yrs_in_ret = ndist_mp edist_mp) age i.country if female == 1, ///
    savefirst savefprefix(fwrfif)

esttab fwro fwrm fwrf fwrfols fwrmols using "../text/replication/RW_to_MP_fwr.tex", `esttab_opt' ///
    alignment(S) indicate(Country dummies = _Icountry*, labels({Yes} {No})) ///
    stats(N widstat, ///
        fmt(%9.0fc 2) layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{S}{@}") ///
        labels(`"Observations"' `"Weak IV F statistic"')) ///
    mtitles("2SLS, all" "2SLS, men" "2SLS, women" "OLS, men" "OLS, women")

esttab fwrfi* using "../text/replication/RW_to_MP_fwr_first.tex", `esttab_opt' ///
    alignment(S) indicate(Country dummies = _Icountry*, labels({Yes} {No})) ///
    stats(N r2_a, ///
        fmt(%9.0fc 4) layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{S}{@}") ///
        labels(`"Observations"' `"adjusted \$R^{2}\$"')) ///
    mtitles("2SLS, all" "2SLS, men" "2SLS, women")
