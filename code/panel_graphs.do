clear all
set more off
*local fmt "eps, "
local fmt "png, width(1200)"
global output ../results

use "../data/derived.dta"
gen retired = 1 - emp_work
label variable retired "Retired"


* Path of cognitive development by working histories
*----------------------------------------------------

keep if age1 >= 50 & age1 <= 70
keep if jobsit1 <= 3
keep if worked_at50 == 1


local cogn twr

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


* Path of individual cognitive performance by age
*-------------------------------------------------

* Sample
preserve
keep if age1 >= 50 & age4 <= 70
keep if wavepart == 124
encode mergeid, gen(id)
xtset id wave
xtdescribe

replace age = int(age)


xtreg twr i.age, fe



