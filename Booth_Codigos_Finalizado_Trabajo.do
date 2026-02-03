import excel "https://github.com/luz-paz/Data-Task/raw/main/Data%20-%202026.xlsx", ///
    sheet("Data") firstrow clear


**-------------------------CLEANING THE DATA--------------------***
**Including all 100% and one 95% participant who answered all key questions
**Reason: To include only those responses that are completed**
drop if Progress!= 100

**Checking whether the design is within or between subject design**

duplicates report ResponseId

**No Duplicates; hence confirmed that it is within-subject conditional
**Same Participant exposed to all the conditions


**Dropping all other irrelevant variables**
**Reason: Does not help in the analysis

drop StartDate EndDate	Status	IPAddress	

drop Progress Finished	RecordedDate	ResponseId	 RecipientLastName

drop	RecipientFirstName	RecipientEmail	ExternalReference	

drop LocationLatitude	LocationLongitude	DistributionChannel	

drop UserLanguage	consent

**dealing with special characters and spaces in the variable names**
**Reason: As Stata does not recognize the variables
ds
foreach v of varlist `r(varlist)' {
    local newname "`v'"
    local newname = subinstr("`newname'", " ", "_", .)
    local newname = subinstr("`newname'", "(", "", .)
    local newname = subinstr("`newname'", ")", "", .)

    if "`newname'" != "`v'" {
        rename "`v'" `newname'
    }
}

drop Q26_Browser Q26_OperatingSystem Q26_Resolution Q26_Version Q26_Version QID54_ClickCount QID54_FirstClick QID54_LastClick QID54_PageSubmit Durationinseconds
rename describe desp

**Labeling Sex and Encoding***
**Reason: Helpful for analysis

describe sex
tab sex, missing
tab sex, nolabel
summ sex, detail
**Only Male and Female in the response, hence assignment accordingly**

gen sex_num = .
replace sex_num = 1 if sex=="Male"
replace sex_num = 2 if sex=="Female"


label define sex_num 1 "male", add
label define sex_num 2 "female", add
label list sex_num
**After labels I also check for missing values

tab sex sex_num, missing
tab sex_num, 
**No missing values generated**
**Check for age in detail**

tab age
**Entry Error Detected as 149 is very likely to be an error while filling the survey
**Dropping the 149 entry observation

gen age_clean = age
replace age_clean = . if age>80
summ age_clean, detail
**Age variable cleaned**

***Likert Scale Coding***
**Reason: Need it to conduct meaningful analysis**

***Generating the range for the scale**
* Keeping original scale labels
* Only use labels for the _range variable

local vars feelings_youalone feelings_bothyoufirst feelings_themalone ///
           feelings_boththemfirst feelings_neither feelings_youaloneforgiven

foreach v of local vars {

    * create the categorical range variable
    gen `v'_range = .

    replace `v'_range = 1 if inrange(`v', -30, -20)
    replace `v'_range = 2 if `v' > -20 & `v' <= -10
    replace `v'_range = 3 if `v' > -10 & `v' <  0
    replace `v'_range = 4 if `v' == 0
    replace `v'_range = 5 if `v' >  0 & `v' <= 10
    replace `v'_range = 6 if `v' > 10 & `v' <= 20
    replace `v'_range = 7 if `v' > 20 & `v' <= 30

}

* define labels for the 7 range categories

label define feelings_range_lbl ///
    1 "Extremely negative (-30 to -20)" ///
    2 "Moderately negative (-20 to -10]" ///
    3 "Slightly negative (-10 to 0)" ///
    4 "Neither positive nor negative (0)" ///
    5 "Slightly positive (0 to 10]" ///
    6 "Moderately positive (10 to 20]" ///
    7 "Extremely positive (20 to 30]", modify

* attaching to all *_range variables

local vars feelings_youalone feelings_bothyoufirst feelings_themalone ///
           feelings_boththemfirst feelings_neither feelings_youaloneforgiven

foreach v of local vars {
    label values `v'_range feelings_range_lbl
}

list feelings_themalone_range in 1/5, nolabel

tab feelings_youalone
tab feelings_bothyoufirst 
tab feelings_themalone 
tab feelings_boththemfirst 
tab feelings_neither 
tab feelings_youaloneforgiven

**Exploratory Analysis

tabstat feelings_youalone, by(feelings_youalone_range)

***Binary Outcome***
**Reason: Encoded binary outcome variable for analysis; as it will be the dependent variable in the analysis. To measure the probability of apology in either case.

**Scenario one where: I apologize first, then ${e://Field/initials} apologizes is coded as 1 and Neither I nor ${e://Field/initials} apologizes is coded as 0. 
* outcome_binary1

gen outcome1_scenario = .
replace outcome1_scenario = 0 if strpos(outcome_binary1, "Neither") > 0
replace outcome1_scenario = 1 if strpos(outcome_binary1, "I apologize first") > 0

**Scenario where the other person is asked to think again. Similar to the scenario; I apologize first, then ${e://Field/initials} apologizes is coded as 1 and Neither I nor ${e://Field/initials} apologizes is coded as 0.
* outcome_binary2

gen outcome2_scenario = .
replace outcome2_scenario = 0 if strpos(outcome_binary2, "Neither") > 0
replace outcome2_scenario = 1 if strpos(outcome_binary2, "I apologize first") > 0

**Creating a blame range with labels similar to feelings as it; where the blameworthy question is meant to made the person think as to how blameworthy the person or the other person in the situation; hence assigning the given labels in the questions and smaller ranges in the step of 25 for later analysis**

**Blame range***

gen blame_1_range = .

replace blame_1_range = 1 if blame_1 == 0
replace blame_1_range = 2 if blame_1 > 0   & blame_1 < 25
replace blame_1_range = 3 if blame_1 >= 25 & blame_1 < 50
replace blame_1_range = 4 if blame_1 == 50
replace blame_1_range = 5 if blame_1 > 50  & blame_1 <= 75
replace blame_1_range = 6 if blame_1 > 75  & blame_1 < 100
replace blame_1_range = 7 if blame_1 == 100

label define blame_lbl ///
    1 "You NOT AT ALL blameworthy (0)" ///
    2 "Other mostly blameworthy (1–24)" ///
    3 "Other moderately blameworthy (25–49)" ///
    4 "Equal blame (50–50)" ///
    5 "You moderately blameworthy (51–75)" ///
    6 "You mostly blameworthy (76–99)" ///
    7 "You ENTIRELY blameworthy (100)", replace

label values blame_1_range blame_lbl
describe blame_1_range
tab blame_1_range, nolabel

**Label Added**

**Attention Check**

gen passedattn_num = .
replace passedattn_num = 1 if passedattn=="yes"
replace passedattn_num = 0 if passedattn=="no"

**Checking for missingness**
tab passedattn passedattn_num, missing

***Checking Lottery Draw and Winner**
describe lottery_draw winner
tab lottery_draw, missing

** Is the winner random?: Using the follow commands to analyze for**
**Regression to analyze if there is any relation between winning the lottery and the guess

summarize lottery_draw, detail
ttest lottery_draw, by(winner)
reg winner lottery_draw

**Results show that clearly; the one who entered one won.
**Hence decided to proceed with creating a distance variable**
**The distance variable variable was created to see the impact if k-level reasoning impacts the attitude towards apology

gen dist1 = abs(lottery_draw - 1)
label var dist1 "Distance from 1 in lottery choice"
summ dist1, detail

**Initiator Type**

gen initiator_num = .
replace initiator_num = 1 if initiator_type == "always"
replace initiator_num = 2 if initiator_type == "conditional"
replace initiator_num = 3 if initiator_type == "never"

tab initiator_type initiator_num, missing

**Constructing a Pro-social index**
**The pro-social index used to aid in the regression analysis**

* Recoding (Reverse-coding) only those variables that are "anti-prosocial"

gen feelings_themalone_pro = -feelings_themalone
gen feelings_neither_pro   = -feelings_neither

* Variables already in prosocial direction 

gen feelings_youalone_pro         = feelings_youalone
gen feelings_bothyoufirst_pro     = feelings_bothyoufirst
gen feelings_boththemfirst_pro    = feelings_boththemfirst
gen feelings_youaloneforgiven_pro = feelings_youaloneforgiven

egen prosocial_index_sum = rowtotal( ///
    feelings_youalone_pro ///
    feelings_bothyoufirst_pro ///
    feelings_themalone_pro ///
    feelings_boththemfirst_pro ///
    feelings_neither_pro ///
    feelings_youaloneforgiven_pro )

**Checking for correlations to check if the coding has been correct**

corr feelings_youalone_pro feelings_bothyoufirst_pro feelings_themalone_pro ///
     feelings_boththemfirst_pro feelings_neither_pro feelings_youaloneforgiven_pro

summarize feelings_themalone feelings_themalone_pro

**Using Cronbach's alpha criteria to see if the help in checking scale reliability

alpha feelings_youalone_pro feelings_bothyoufirst_pro feelings_themalone_pro ///
      feelings_boththemfirst_pro feelings_neither_pro feelings_youaloneforgiven_pro
	  
* Improving score; running the code to check which items are weakest among the list and working on creating a more concise list **

alpha feelings_youalone_pro feelings_bothyoufirst_pro feelings_themalone_pro ///
      feelings_boththemfirst_pro feelings_neither_pro feelings_youaloneforgiven_pro, item

**Low relaibility 0.51***	  
**core ones now: with strongest correlation**
* prosocial core index (3 items)

egen prosocial_index_core = rowtotal( ///
    feelings_youalone_pro ///
    feelings_bothyoufirst_pro ///
    feelings_youaloneforgiven_pro )

**Checking for Cronbach's alpha again**

alpha feelings_youalone_pro feelings_bothyoufirst_pro feelings_youaloneforgiven_pro

**The scale relaibility scale has jumped to 0.681**

**Before running summary statistics , checking for range, missingness (sanity check!)**

**sanity and missingness**
* Check range

summ feelings_youalone feelings_bothyoufirst feelings_themalone ///
     feelings_boththemfirst feelings_neither feelings_youaloneforgiven, detail

summ blame_1, detail
summ lottery_draw age, detail
summ sex_num, detail
summ initiator_num, detail
summ dist1, detail

* missingness
misstable summarize
misstable summarize outcome_binary1 outcome_binary2 age_clean sex_num initiator_type passedattn lottery_draw feelings_youalone feelings_bothyoufirst feelings_themalone feelings_boththemfirst feelings_neither feelings_youaloneforgiven prosocial_index_core 

**Intital Summary Statistics Table**

estpost tabstat age_clean prosocial_index_core sex_num blame_1 dist1   ///
    if !missing(age_clean), ///
    stat( mean sd min max n) columns(statistics)

esttab using "summstats11.tex", replace ///
    cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))") ///
    nonumber noobs label

**Preliminary Regressions**
**Logit Regressions to chck the impact on outcome 1 and outcome 2; without including intentions or feelings (a sort of baseline to see if some other factors are playing a role)

logit outcome1_scenario c.dist1 i.sex_num c.age , vce(robust)
margins, atmeans
logit outcome2_scenario c.dist1  i.sex_num c.age , vce(robust)
margins, atmeans

**Outcome of Scenario 1 has a greater probability in general but none of them are significant. 

**Using firthlogit because initiator num and attentions check  prefectly predicted in case of logit. HOWEVER, THE KEY REASON WAS IT REDUCES SMALL SAMPLE BIAS by providing the case of 

firthlogit outcome1_scenario i.initiator_num passedattn_num c.feelings_youalone	c.feelings_bothyoufirst	c.feelings_themalone c.feelings_boththemfirst	c.feelings_neither	c.feelings_youaloneforgiven blame_1 c.age i.sex_num c.dist1


firthlogit outcome2_scenario i.initiator_num passedattn_num c.feelings_youalone	c.feelings_bothyoufirst	c.feelings_themalone c.feelings_boththemfirst	c.feelings_neither	c.feelings_youaloneforgiven blame_1 c.age i.sex_num c.dist1


firthlogit outcome1_scenario prosocial_index_core i.initiator_num blame_1 

**None of the results provide any insight; though intentions type==3 does provide some insight. 

**So we use a probit model instead**

probit outcome1_scenario c.dist1  i.sex_num c.age  c.feelings_youalone	c.feelings_bothyoufirst	c.feelings_themalone	c.feelings_boththemfirst	c.feelings_neither	c.feelings_youaloneforgiven c.blame_1
margins, dydx(feelings_neither blame_1 age sex_num)
eststo ame1


probit outcome2_scenario c.dist1  i.sex_num c.age  c.feelings_youalone	c.feelings_bothyoufirst	c.feelings_themalone	c.feelings_boththemfirst	c.feelings_neither	c.feelings_youaloneforgiven c.blame_1
margins, dydx(feelings_neither blame_1 age sex_num)
eststo ame2

**Exporting to ESTTAB TABLE**
esttab ame1 ame2 using "AME_table.tex", replace ///
    cells("b(fmt(3)) se(fmt(3) par)") ///
    label nonumber noobs ///
    mtitles("Outcome 1" "Outcome 2") ///
    title("Average Marginal Effects (Probit Models)") ///
    varlabels( ///
        2.sex_num "Female (vs Male)" ///
        age "Age" ///
        feelings_neither "Feelings: Neither positive nor negative" ///
        blame_1 "Blame" ///
    )

**Age, Blame and Feeling neither positive or negative remain strong drivers; hence we include it in Appendix of the document**
**Using Pro-social Index core**

probit outcome1_scenario c.dist1 i.sex_num c.age c.prosocial_index_core	c.feelings_neither	c.feelings_youaloneforgiven c.blame_1, vce (robust)
margins, atmeans

probit outcome2_scenario c.dist1 i.sex_num c.age c.prosocial_index_core	c.blame_1, vce (robust)
margins, atmeans

probit outcome1_scenario c.dist1 i.sex_num c.age c.prosocial_index_core, vce (robust) 
margins, atmeans

probit outcome2_scenario c.dist1 i.sex_num c.age c.prosocial_index_core, vce (robust)	
margins, atmeans

probit outcome1_scenario c.dist1 i.sex_num c.age c.blame_1, vce (robust) 
margins, atmeans

probit outcome2_scenario c.dist1 i.sex_num c.age c.blame_1, vce (robust)
margins, atmeans

**Confounding and Sobel Test**
*prosocial_index_core is statistically significant in the outcome2 model when blame is excluded, but loses its significance once blame_1 is included. This suggests that blame can be an important confounding factor or potential mediating mechanism: individuals with higher prosociality may also systematically assign different levels of blame, and blame itself can strongly predict the outcome. 

*Comments: From the margins and regression output of the probit some things can be concluded*

*In probit models where the outcome is 1 if the participant apologizes first and 0 if neither, for both Scenario 1 and Scenario 2. In Scenario 1, feeling "neither" responsible reduces the chance of apologizing, while higher blame increases it. Sex also has a small effect, with women less likely to apologize. 

*In Scenario 2, blame is again a strong predictor, and prosocial orientation slightly increases the probability of apologizing. Overall, it looks like how responsible participants feel drives whether they choose to apologize.

**Mediation Test using Sobel with blame being the mediator**

**blame does play a mediator (Mv) and iv is prosocial index, using the following test we get the following***


sgmediation2 outcome2_scenario, iv(prosocial_index_core) mv(blame_1) cv(age i.sex_num)
return list
* 1. Create a matrix of the results
matrix mediation = (r(a_coef) \ r(b_coef) \ r(ind_eff) \ r(dir_eff) \ r(tot_eff) \ r(szstat)) 

* 2. Give the rows names so the table looks professional
matrix rownames mediation = "Path a (IV->M)" "Path b (M->DV)" "Indirect Effect" "Direct Effect" "Total Effect" "Sobel z"

* 3. Export to overleaf 
esttab matrix(mediation) using "mediation_results.tex", ///
    cells(fmt(3)) /// show 3 decimal places
    label replace ///
    title("Mediation Analysis Results") ///
    nonumber

sgmediation2 outcome1_scenario, iv(prosocial_index_core) mv(blame_1) cv(age i.sex_num)
return list
* 1. Create a matrix of the results
matrix mediation = (r(a_coef) \ r(b_coef) \ r(ind_eff) \ r(dir_eff) \ r(tot_eff) \ r(szstat)) 

* 2. Give the rows names so the table looks professional
matrix rownames mediation = "Path a (IV->M)" "Path b (M->DV)" "Indirect Effect" "Direct Effect" "Total Effect" "Sobel z"

* 3. Export to overleaf 
esttab matrix(mediation) using "mediation_results1.tex", ///
    cells(fmt(3)) /// show 3 decimal places
    label replace ///
    title("Mediation Analysis Results") ///
    nonumber
**bootstrapping the effect, so that more replications improve the model***
bootstrap r(ind_eff) r(dir_eff) r(tot_eff), reps(1000): ///
sgmediation2 outcome2_scenario, iv(prosocial_index_core) mv(blame_1) cv(age i.sex_num)

estat bootstrap, bc percentile

***Probit Analysis: to be included in the paper***
**Testing Hypothesis 1**
eststo clear
probit outcome1_scenario c.prosocial_index_core c.dist1 c.age_clean i.sex_num , vce (robust)

margins, atmeans at(prosocial_index_core=(0(5)50)) post

outreg2 using "marginsnew1.tex", tex replace se

eststo clear
probit outcome2_scenario c.prosocial_index_core c.dist1 c.age_clean i.sex_num , vce (robust)

margins, atmeans at(prosocial_index_core=(0(5)50)) post

outreg2 using "marginsnew2.tex", tex replace se

***Testing Hypothesis 2***
eststo clear
probit outcome1_scenario c.prosocial_index_core c.dist1 c.age_clean i.sex_num, vce (robust)

margins, dydx(sex_num) post


outreg2 using "margins3.tex", tex replace se

eststo clear
probit outcome2_scenario c.prosocial_index_core c.dist1 c.age_clean i.sex_num, vce (robust)

margins, dydx(sex_num) post

outreg2 using "margins4.tex", tex replace se

****Testing Hypothesis 3**

eststo clear
probit outcome2_scenario c.prosocial_index_core c.dist1 c.age_clean i.sex_num , vce (robust)
margins, atmeans at(age_clean=(0(5)50)) post
outreg2 using "margins8.tex", tex replace se

eststo clear
probit outcome1_scenario c.prosocial_index_core c.dist1 c.age_clean i.sex_num , vce (robust)
margins, atmeans at(age_clean=(0(5)50)) post
outreg2 using "margins9.tex", tex replace se

**Margins Plots**

**Hypothesis 1: Proscial Index Core Plot**

probit outcome1_scenario c.prosocial_index_core c.dist1 c.age_clean i.sex_num , vce (robust)
margins, atmeans at(prosocial_index_core=(0(5)50))
marginsplot, ///
    recast(line) recastci(rarea) ///
	 plotopts(lcolor(red*0.6) lwidth(medthick)) ///
	  ciopts(color(red%20) lcolor(red%0)) ///
    xtitle("Prosocial Index Core") ///
    ytitle("Predicted probability of Outcome 1") ///
    yscale(range(0 1)) ylabel(0(0.2)1)

probit outcome2_scenario c.prosocial_index_core c.dist1 c.age_clean i.sex_num,  vce (robust)
margins, atmeans at(prosocial_index_core=(0(5)50))
marginsplot, ///
    recast(line) recastci(rarea) ///
	 plotopts(lcolor(red*0.6) lwidth(medthick)) ///
	  ciopts(color(red%20) lcolor(red%0)) ///
    xtitle("Prosocial Index Core") ///
    ytitle("Predicted probability of Outcome 2") ///
    yscale(range(0 1)) ylabel(0(0.2)1)

**Hypothesis 2**
**For Hypothesis 2; the margins table is more insightful**
	
**Hypothesis 3: Age Margin Plot**

probit outcome2_scenario c.prosocial_index_core c.dist1 c.age_clean i.sex_num,  vce (robust)
margins, atmeans at(age_clean=(0(5)50))
marginsplot, ///
    recast(line) recastci(rarea) ///
	 ciopts(color(gs12%40) lcolor(gs12%0)) ///
    xtitle("Age") ///
    ytitle("Predicted probability of Outcome 2") ///
    yscale(range(0 1)) ylabel(0(0.2)1)

probit outcome1_scenario c.prosocial_index_core c.dist1 c.age_clean i.sex_num,  vce (robust)
margins, atmeans at(age_clean=(0(5)50))
marginsplot, ///
    recast(line) recastci(rarea) ///
	 ciopts(color(gs12%40) lcolor(gs12%0)) ///
    xtitle("Age") ///
    ytitle("Predicted probability of Outcome 1") ///
    yscale(range(0 1)) ylabel(0(0.2)1)

**Robustness Check**
**Checkng for Robust to Model Specification**
**Change the model specification to Logit**
**Testing Hypothesis 1**
eststo clear
logit outcome1_scenario c.prosocial_index_core c.dist1 c.age_clean i.sex_num , vce (robust)

margins, atmeans at(prosocial_index_core=(0(5)50)) post

outreg2 using "marginslog1.tex", tex replace se

eststo clear
logit outcome2_scenario c.prosocial_index_core c.dist1 c.age_clean i.sex_num , vce (robust)

margins, atmeans at(prosocial_index_core=(0(5)50)) post

outreg2 using "marginslog2.tex", tex replace se

***Testing Hypothesis 2***
eststo clear
logit outcome1_scenario c.prosocial_index_core c.dist1 c.age_clean i.sex_num, vce (robust)

margins, dydx(sex_num) post


outreg2 using "marginss1.tex", tex replace se

eststo clear
logit outcome2_scenario c.prosocial_index_core c.dist1 c.age_clean i.sex_num, vce (robust)

margins, dydx(sex_num) post

outreg2 using "marginss2.tex", tex replace se

****Testing Hypothesis 3**

eststo clear
logit outcome2_scenario c.prosocial_index_core c.dist1 c.age_clean i.sex_num , vce (robust)
margins, atmeans at(age_clean=(0(5)50)) post
outreg2 using "marginsg1.tex", tex replace se

eststo clear
logit  outcome1_scenario c.prosocial_index_core c.dist1 c.age_clean i.sex_num , vce (robust)
margins, atmeans at(age_clean=(0(5)50)) post
outreg2 using "marginsg2.tex" , tex replace  se

