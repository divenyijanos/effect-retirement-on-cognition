
***** CREATING MERGED WORKFILE FROM WAVES 1 2 & 4 *****
*******************************************************
* merge and clear, creates: merged_waves.dta

clear
set more off

* You should pass the path to the folder of raw data when running this file
global rawdata `1'

tempfile wave1 wave2 wave4

** MERGE WAVE 1 & 2 **

foreach num of numlist 1 2 {

   	* COVER
	local cover mergeid gender mobirth yrbirth cvidp ///
        mstat int_year* int_month*
	use `cover' using $rawdata/w`num'/sharew`num'_rel2-6-0_cv_r, clear
	drop if mergeid=="no int w.`num'"
	rename int_year iv_year
	rename int_month iv_month
    gen wave = `num'
	save `wave`num'', replace

    * IMPUTATION
	use implicat mergeid country wave* edu  hgtincv hnetwv ///
	    numeracy /*various questions*/ ///
        using $rawdata/w`num'/sharew`num'_rel2-6-0_imputations
	keep if implicat==1 /*used for imputation*/
	drop implicat
	sort mergeid
	drop if mergeid=="no int w.`num'"
	merge 1:1 mergeid using `wave`num'', keep(match using) nogenerate
	save `wave`num'', replace

	* COGNITIVE
	use mergeid cf001-cf017 using $rawdata/w`num'/sharew`num'_rel2-6-0_cf, clear
	sort mergeid
	merge 1:1 mergeid using `wave`num'', keep(match) nogenerate
	save `wave`num'', replace

    * HEALTH
    local health mergeid sphus chronic bmi adl iadl cusmoke eurod numeracy
    use `local' using $rawdata/w`num'/sharew`num'_rel2-6-0_gv_health, clear
    capture rename chronicw2 chronic
    keep `health'
    sort mergeid
	merge 1:1 mergeid using `wave`num'', keep(match) nogenerate
	save `wave`num'', replace

    use $rawdata/w`num'/sharew`num'_rel2-6-0_gs, clear
    keep mergeid gs006_ gs007_ gs008_ gs009_
    sort mergeid
    merge 1:1 mergeid using `wave`num'', keep(match) nogenerate
    save `wave`num'', replace

	* EMPLOYMENT
	use $rawdata/w`num'/sharew`num'_rel2-6-0_ep, clear
    capture rename ep009_1 ep009
    capture rename ep021_1 ep021
    keep mergeid ep002 ep005_ ep013* ep037 ep050 ep009 ep021 ep064d*
	merge 1:1 mergeid using `wave`num'', keep(match) nogenerate
	save `wave`num'', replace

    * DEMOGRAPHICS
    use mergeid ch001 using $rawdata/w`num'/sharew`num'_rel2-6-0_ch, clear
    sort mergeid
	merge 1:1 mergeid using `wave`num'', keep(match) nogenerate
	save `wave`num'', replace

    use mergeid dn026* using $rawdata/w`num'/sharew`num'_rel2-6-0_dn, clear
    sort mergeid
	merge 1:1 mergeid using `wave`num'', keep(match) nogenerate
	save `wave`num'', replace
    }

use mergeid iscedy_r using $rawdata/w1/sharew1_rel2-6-0_gv_isced,clear
sort mergeid
drop if mergeid=="no int w.1"
merge 1:1 mergeid using `wave1', keep(match) nogenerate
save `wave1', replace

*End of life from wave 3 and 4*
use mergeid sl_xt009 using $rawdata/w3/sharew3_rel1_xt, clear
rename sl_xt009 yrdeath
sort mergeid
merge 1:1 mergeid using `wave2', keep(match using) nogenerate
save `wave2', replace

use mergeid xt009 using $rawdata/w4/sharew4_rel1-0-0_xt, clear
rename xt009 yrdeath
sort mergeid
merge 1:1 mergeid using `wave2', keep(match using) nogenerate
save `wave2', replace


* Put together the waves
append using `wave1'

* Renaming those which are different in wave 4
rename iscedy_r yeduc
rename edu isced_r

gen wrkhrs = ep013_1 /* wave 1 */
replace wrkhrs = ep013_2 if ep013_1 >= .
replace wrkhrs = ep013_1 + ep013_2 if ep013_1 < . & ep013_2 < .
lab var wrkhrs "Weekly working hours from main and secondary job"
replace wrkhrs = ep013_ if wave == 2 /* wave 2*/
drop ep013*

compress
save ../data/merged_waves, replace

** MERGE WAVE 4 **

	* COVER
	local cover4 `cover' country mobirthp yrbirthp waveid
    use `cover4' using $rawdata/w4/sharew4_rel1-0-0_cv_r
    drop gender /*get later from imputations*/
    drop if mergeid == "no int w.4"
    rename int_year iv_year
	rename int_month iv_month
	gen wave = 4

	save `wave4'

	* COGNITIVE
	use mergeid cf001-cf002 using $rawdata/w4/sharew4_rel1-0-0_cf, clear
	sort mergeid
	merge 1:1 mergeid using `wave4', keep(match) nogenerate
	save `wave4', replace

    *IMPUTATIONS*
    local keepimput mergeid implicat gender yeduc cjs pwork ///
         chronic bmi eurod adl iadl sphus  wllft wllst fluency numeracy1
    use `keepimput' using $rawdata/w4/sharew4_rel1-0-1_gv_imputations, clear
    rename cjs ep005_ /*same naming as in waves 1&2*/
    rename pwork ep002_
    rename wllft cf008tot
    rename wllst cf016tot
    rename numeracy1 numeracy
    rename fluency cf010_
    keep if implicat == 1 /* 5 imputation for each observation */
    drop implicat

    sort mergeid
    merge 1:1 mergeid using `wave4', keep(match) nogenerate
	save `wave4', replace

    * GRIP STRENGTH
    use $rawdata/w4/sharew4_rel1-0-0_gs, clear
    keep mergeid gs006_ gs007_ gs008_ gs009_
    sort mergeid

    merge 1:1 mergeid using `wave4', keep(match) nogenerate
    save `wave4', replace

    * EMPLOYMENT
    use $rawdata/w4/sharew4_rel1-0-0_ep, clear
    keep mergeid ep013
    rename ep013 wrkhrs
    sort mergeid

    merge 1:1 mergeid using `wave4', keep(match) nogenerate
    save `wave4', replace

    * DEMOGRAPHIC
    use $rawdata/w4/sharew4_rel1-0-0_gv_isced, clear
    keep mergeid isced_r
    sort mergeid
    merge 1:1 mergeid using `wave4', keep(match) nogenerate
    save `wave4', replace

    sharetom4*
    compress
    save `wave4', replace


append using ../data/merged_waves
compress
save ../data/merged_waves, replace


*** CLEANING ***

mvdecode cf* gs*, mv(-1 -2)
mvdecode `health', mv(-1 -2)
mvdecode mobirth yrbirth ep* dn* ch001, mv(-1 -2)

replace cusmoke = 0 if cusmoke == 2 /* never smoked */
replace cusmoke = 1 if cusmoke == 5 /* smoked but stopped */

foreach var of varlist ep021 ep002 dn026* {
    replace `var' = 0 if `var' == 5
    }

*** RENAMING VARIABLES ***

* Cognitive
rename cf001 selfread
rename cf002 selfwrite
rename cf008 fwr
rename cf010 fluency
rename cf016 dwr
drop cf*

* Employment
rename ep002 didpaidwork
rename ep005_ jobsit
rename ep009 jobtype
rename ep021 responsible
rename ep050 y_last_job_end

* Health
rename gs006 gs_l1
rename gs007 gs_l2
rename gs008 gs_r1
rename gs009 gs_r2
rename sphus genhealth

* Other, only in wave 1 & 2
rename ep037 afraidhealthlimit /*only for wave 1 and 2*/
rename ch001 numchild
rename dn026_1 malive
rename dn026_2 falive

/*
*** RESTRUCTURE AS PANEL ***
drop if waveid>60 /* drop those who weren't there at the beginning */
sort mergeid

encode(mergeid), gen(id)

sort id wave
xtset id wave
*/

*** Generate wave participation overview variable (from EASYSHARE) ***

local wavelist "1 2 4"
foreach w in `wavelist'  {
    gen temp1_`w' = `w' if wave==`w'
    egen temp2_`w' = max(temp1_`w'), by(mergeid)
}
gen wavepart = ""
foreach w in `wavelist' {
    replace wavepart = wavepart + string(temp2_`w')  if string(temp2_`w')!="."
}
destring wavepart, replace
lab var wavepart "wave participation pattern"

drop temp1_* temp2_*

sort mergeid wave


*** GENERATING BASIC NEW VARIABLES ***

* General variables
replace iv_year=2011 if iv_year==. /*some are missing for wave 4*/
replace iv_month=1 if iv_month==. /*arbitrarily choose january*/

by mergeid: egen mbirth=max(mobirth) /*impute missing*/
by mergeid: egen ybirth=max(yrbirth)
drop mobirth yrbirth

gen iv_time=ym(iv_year, iv_month)
gen birth=ym(ybirth, mbirth)
gen age=int((iv_time-birth)/12)
replace age= iv_year - ybirth if mbirth==.
gen agem=iv_time-birth
lab var age "Age"
lab var agem "age (in months)"

gen relevantage=(age>=50 & age<=75)
lab var relevantage "aged between 50 and 75 (dummy)"

gen byte male= 2-gender
gen byte female= gender-1
lab var female "Female"

gen temp_c = substr(mergeid, 1, 2) /* impute country from mergeid */
*tab temp_c if country == .
replace country = 17 if temp_c == "FR"
replace country = 25 if temp_c == "Ia" | temp_c == "Ih" | temp_c == "Ir"
replace country = 30 if temp_c == "IE"
drop temp_c

* Job situation dummies
gen ret=(jobsit==1) if jobsit<.
lab var ret "Retired"
gen emp=(jobsit==2) if jobsit<.
lab var emp "Employed"
lab def emp_l 0 "not employed" 1 "employed"
lab val emp emp_l
gen unemp=(jobsit==3) if jobsit<.
lab var unemp "Unemployed"
gen disab=(jobsit==4) if jobsit<.
lab var disab "Permanently sick or disabled"
gen js_other=(jobsit>4) if jobsit<.
lab var js_other "Other, mainly homemaker"

* Reason for retirement
gen retired_eligibility = 0
    replace retired_eligibility = 1 if ep064d1 == 1 | ep064d2 == 1 | ep064d3 == 1

* Education
by mergeid: egen isced=max(isced_r) /*imput missing*/
    replace isced_r=isced if isced_r==.

tab isced_r, gen(educ)
foreach i of numlist 1/7 {
	local j = `i'-1
	rename educ`i' educ`j'
	}
gen educ_other=(educ8 | educ9)
replace educ_other=. if isced_r==.
drop educ8 educ9
lab var educ_other "Other and still in school"

mvdecode yeduc, mv(-1 -2 95 97)
by mergeid: egen yeduc_m=max(yeduc)  	/*imput missing*/
	replace yeduc=yeduc_m if yeduc==.

/*

*Creating spouse's age FIXME: revise this
gen hhid = substr(mergeid,1,9)
encode(hhid), gen(hid)

by hid wave, sort: egen numspous = total(mstat) if mstat == 1
by hid wave: egen ytot = total(ybirth) if mstat == 1 & numspous == 2
by hid wave: egen mtot = total(mbirth) if mstat == 1 & numspous == 2

replace yrbirthp = ytot - ybirth if wave < 4
replace mobirthp = mtot - mbirth if wave < 4

rename yrbirthp ybirthp /*standardizing naming*/
rename mobirthp mbirthp

gen birthp = ym(ybirthp, mbirthp)
gen agep = int((iv_time-birthp)/12)

drop ytot mtot numspous birthp
*/

compress
save ../data/merged_waves, replace
