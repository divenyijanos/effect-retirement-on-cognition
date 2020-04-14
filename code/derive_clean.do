
*** THE EFFECT OF RETIREMENT ON COGNITIVE PERFORMANCE ***
** CREATING DERIVED FOR FURTHER ANALYSIS

clear all
set more off
use ../data/merged_waves

*** NEW VARIABLES ***************************************

*total word recall (TWR)
egen twr=rowtotal(fwr dwr), missing
lab var twr "Total word recall (TWR)"

*age
gen agesq = age^2
lab var agesq "Age (sq.)"

foreach num of numlist 1 2 4 {
    gen temp_age`num' = age if wave == `num'
    by mergeid, sort: egen age`num' = min(temp_age`num')
    lab var age`num' "Age at wave `num'"
}

by mergeid: egen ydecease = max(yrdeath)
drop yrdeath temp_*


egen age_cat = cut(age), at(50(5)70)
replace age_cat = 70 if age >= 70
replace age_cat = 0 if age < 50

*education
egen educ_cat = cut(isced), at(0,2,5,95,100)


*Recode categorical variables to have higher values be better
lab def self 1 "Poor" 2 "Fair" 3 "Good" 4 "Very Good" 5 "Excellent"
foreach var of varlist genhealth selfread selfwrite {
	replace `var'=6-`var'
	lab val `var' self
}

*Number of observation
*egen nobs = count(country)

* impute y_last_job_end for each wave
egen latest_job_end = max(y_last_job_end), by(mergeid)
replace y_last_job_end = latest_job_end if y_last_job_end == .
drop latest_job_end

* Other definitions for job situation (did paid work, working hours)
gen emp_work = (emp==1) if emp < .
replace emp_work = 1 if didpaidwork==1
       /*didpaidwork not asked from those who have jobsit=emp*/
replace emp_work = 0 if emp_work == . & y_last_job_end < .
lab var emp_work "Employed (did any paid work last 4 w | jobsit=emp)"

gen ret_work=(ret==1) if ret < .
replace ret_work=0 if didpaidwork==1
lab var ret_work "Retired (and did not paid work)"

replace wrkhrs = 0 if wrkhrs >= . & jobsit < .
replace wrkhrs = . if wrkhrs < 0

foreach num of numlist 0 15 20 {
	gen emp_h`num' = 0  if jobsit < .
        /* generate variable for all who have obs for jobsit */
	replace emp_h`num' = 1 if wrkhrs > `num' & wrkhrs < .
        /* define employed as worked some hours */
	lab var emp_h`num' "Employed (worked `num'+ hours)"
	}

gen ret_h = (ret==1) if jobsit < .
replace ret_h = 0 if wrkhrs > 0 & wrkhrs < .
lab var ret_h "Retired (and don't work any (+)hours)"
    /*zero hours alone would not surely mean retirement*/


* Country names, country codes
decode country, gen(cname)
gen countrycode = ""
    replace countrycode = "AT" if country == 11
    replace countrycode = "DE" if country == 12
    replace countrycode = "SE" if country == 13
    replace countrycode = "NL" if country == 14
    replace countrycode = "ES" if country == 15
    replace countrycode = "IT" if country == 16
    replace countrycode = "FR" if country == 17
    replace countrycode = "DK" if country == 18
    replace countrycode = "GR" if country == 19
    replace countrycode = "CH" if country == 20
    replace countrycode = "BE" if country == 23

/*
* attach PISA2000 scores
merge m:1 country using ../data/pisa2000.dta
drop _m
*/
*** CREATING IV *************

* merge eligibilities according to Rohwedder-Willis
csvmerge country gender using ../data/RW_eligibility.csv
drop _m

* merge eligibilities according to Mazzonna-Peracchi
* (we lose the countries which have no eligibility age)
preserve
tempfile mp_elig
import delimited ../data/MP_eligibility.csv, clear
save `mp_elig'
restore

joinby country gender using `mp_elig'
gen birthdate = ym(ybirth, mbirth)
    replace birthdate = ym(ybirth, 1) if birthdate == .
gen validitydate = ym(y_validfrom, m_validfrom)
gen daydifference = birthdate - validitydate
drop if daydifference < 0
egen mindays = min(daydifference), by(mergeid)
keep if daydifference == mindays
* if birthdate is missing, keep the first one
duplicates drop mergeid wave, force
drop *_validfrom birthdate validitydate daydifference mindays


* eligibility variables for early and normal retirement, by RW and MP

levelsof wave, local(waves)

foreach author in rw mp {

    foreach l in e n { /*early/normal*/

        if "`l'" == "e" {
            local rettitle early
            }
        if "`l'" == "n" {
            local rettitle normal
            }

        gen `l'dist_`author' = age
        lab var `l'dist_`author' "Years after `rettitle' eligibility"
        replace `l'dist_`author' = age - `rettitle'_`author'

        gen `l'elig_`author' = 0 if age < .
        replace `l'elig_`author' = 1 if `l'dist_`author' >= 0 & `l'dist_`author' < .
        lab var `l'elig_`author' "Eligible for `rettitle' retirement"

        foreach w in `waves' {
    		local var `l'elig`w'_`author'
    		gen `var'_t = 0 if wave == `w'
    		replace `var'_t = 1 if `l'elig_`author' == 1 & wave == `w'
    	 	by mergeid, sort: egen `var' = max(`var'_t)
    	 	lab var `var' "Eligible for `rettitle' retirement at wave `w'"
    		drop `var'_t
    	}

        local var1 d12_`l'elig_`author'
        gen `var1' = 0 if wavepart == 124 | wavepart == 12
        lab var `var1' "Became eligible for `rettitle' retirement between period 1 and 2"
        replace `var1' = 1 if `l'elig2_`author'-`l'elig1_`author' == 1

        local var2 d24_`l'elig_`author'
        gen `var2' = 0 if wavepart == 124 | wavepart == 24
        lab var `var2' "Became eligible for `rettitle' retirement between period 2 and 4"
        replace `var2' = 1 if `l'elig4_`author'-`l'elig2_`author' == 1

        local var3 d14_`l'elig_`author'
        gen `var3' = 0  & wavepart == 14
        lab var `var3' "Became eligible for `rettitle' retirement between period 1 and 4"
        replace `var3' = 1 if `l'elig4_`author'-`l'elig1_`author' == 1 & wavepart == 14
    }
}

*** DEPENDENT VARIABLE: Cognition change **********************

/* FIXME this part is not working currently
gen pd_orient = 1 /*period*/
replace pd_orient = 0 if cf_orient2*cf_orient3!=1
replace pd_orient = . if cf_orient1==.
by mergeid: egen orient = min(pd_orient)
lab var orient "No problem with orientation (month&year) in any period"
*/

sort mergeid wave

local cogn fwr dwr twr numeracy fluency
foreach var of varlist `cogn' {
    foreach w in `waves' {
        gen temp_`var'_`w' = `var' if wave == `w'
        by mergeid: egen `var'`w' = max(temp_`var'_`w')
    }
    gen d12_`var' = `var'2 - `var'1
    gen d24_`var' = `var'4 - `var'2
}
drop temp_*

*** GENERATE TIME VARIABLES *************************************
gen ivdate = ym(iv_year, iv_month) /* no missing */
foreach w in `waves' {
    gen temp_ivdate_`w' = ivdate if wave == `w'
    by mergeid: egen ivdate`w' = max(temp_ivdate_`w')
}
drop temp_*

gen d12_years = (ivdate2 - ivdate1) / 12
gen d24_years = (ivdate4 - ivdate2) / 12
gen d14_years = (ivdate4 - ivdate1) / 12


*** LABOR MARKET HISTORY variables creation ********************

local emp emp_work /* choose employment definition */

* labor market history by waves
gen pd_hist = wave*`emp' /*0 if not worked in that wave, wave number if worked*/
by mergeid: egen tot_hist = total(pd_hist)
by mergeid: egen nobs_emp = count(`emp')
gen hist = tot_hist
replace hist = 100 if tot_hist == 1
replace hist = 110 if tot_hist == 3
replace hist = 101 if tot_hist == 5
replace hist = 111 if tot_hist == 7
replace hist = 10 if tot_hist == 2 /*obviously, it means 010*/
replace hist = 1 if tot_hist == 4 /*001*/
replace hist = 11 if tot_hist == 6 /*011*/

replace hist = 100 if nobs==2 & tot_hist==1 & ydec < . /*if known that died*/
drop tot_hist pd_hist
lab var hist "working history code"

gen leftlm =0
replace leftlm = 1 if hist == 100 & wave == 2
replace leftlm = 1 if hist == 100 & wave == 4 & wavepart == 14
replace leftlm = 1 if hist == 110 & wave == 4
replace leftlm = . if wave == 1
replace leftlm = . if emp_work == .
lab var leftlm "Left labor market in last period"

/*
gen D_wrkhrs=wrkhrs-L.wrkhrs
gen D2_wrkhrs=wrkhrs-L2.wrkhrs
gen DD_wrkhrs=D2_wrkhrs-L2.D_wrkhrs
by mergeid: egen d24_wrkhrs=max(D2_wrkhrs)
by mergeid: egen d12_wrkhrs=max(D_wrkhrs)
*/

forvalues num = 1/2 {
        gen temp_wrkhrs`num' = wrkhrs if wave == `num'
        by mergeid: egen wrkhrs`num' = max(temp_wrkhrs`num')
        drop temp_
        }
/*
gen dp12_wrkhrs=d12_wrkhrs/wrkhrs1
gen dp24_wrkhrs=d24_wrkhrs/wrkhrs2
*/


* years in retirement (years after last job)
gen yrs_in_ret = iv_year - y_last_job_end
    replace yrs_in_ret = . if yrs_in_ret > age | y_last_job_end == .
    replace yrs_in_ret = 0 if `emp' == 1 | yrs_in_ret < 0
* clean years in retirement
replace yrs_in_ret = d12_years/2 ///
    if d12_years < yrs_in_ret & leftlm == 1 & wave == 2
replace yrs_in_ret = d24_years/2 ///
    if d24_years < yrs_in_ret & leftlm == 1 & wave == 4
replace yrs_in_ret = d14_years/2 ///
    if d14_years < yrs_in_ret & leftlm == 1 & wave == 4
label variable yrs_in_ret "Years in retirement"

* worked at age 50
gen worked_at50 = (age - yrs_in_ret >= 50)
    replace worked_at50 = . if (age == . | yrs_in_ret == .)
label variable worked_at50 "Worked at age 50"

* impute worked_at50
egen worked_ever_at50 = max(worked_at50), by(mergeid)
    replace worked_at50 = worked_ever_at50
drop worked_ever_at50

foreach w in `waves' {
	gen temp_jobsit_`w' = jobsit if wave == `w'
	by mergeid: egen jobsit`w' = max(temp_jobsit_`w')
	drop temp_jobsit_`w'
}


compress

label data "workfile for Effect of Retirement on Cognition"
save ../data/derived, replace
