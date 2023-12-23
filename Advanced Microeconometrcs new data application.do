clear all
cd "/Users/samueleborsini/Library/Mobile Documents/com~apple~CloudDocs/Università/Economics and econometrics/II anno/Advanced Microeconometrics/Project/Data analysis"

scalar t1 = c(current_time)

capture log close
log using "New data application - Advanced Microeconometrics", replace

***********************************************
/*
New data application using simulated based methods - Advanced microeconometrics.

"Effect of high school satisfaction on studying and working decisions"

Samuele Borsini, Stella Gatti & Pablo Suarez-Sucunza
October 31st, 2023
*/
***********************************************

***********************************************
/*
1.- Introduction and motivation:

We want to study whether a high school student being satisfied or not with high school (in this case regarding the study plan of the high school) has an impact on its decisions post-graduation, most specifically on its decision to go to university or start working.

The choices students make upon completing high school significantly impact their future paths and contributions to society. The quality of one's high school experience can significantly shape their future trajectory, affecting their academic pursuits and career choices. This research addresses a crucial aspect of educational and career development, shedding light on the factors that influence these decisions.

We plan to study this by modelling both the probability that a student enrolls in university the year after graduation, and the probability that the student has a job the year after graduation.

Since these 2 decisions are most likely related, it makes sense to model them together. To account for unobserved characteristics, as for example skill, affect these decisions but also affect the high school satisfaction of the student, we account for this by also modelling the probability that a student is satisfied with high school. Overall, we propose a trivariate probit model. We will expand more on this a bit further.

We will start by modelling each probability separately, the jointly, and finally accounting for the endogeneity of high school satisfaction.
*/
***********************************************


***********************************************
/*
2.- Data: 

We use microdata from ISTAT about "path of study work of high school graduates" (https://www.istat.it/it/archivio/96042). The data was published in 2015, and belongs to students who inished high school in 2011. The interviews were conducted almost 4 years after the students had graduated. We have data on 26,235 students.
*/
import delimited "Data/GEPPS_2015_IT_TXT/MICRODATI/GEPPS_Microdati_Anno_2015.txt", clear


keep v3_3 v4_49 v0_5 cittad v1_7d scuola_pubblica v0_3_micro v1_1 v0_8 v1_3 v6_5 v6_10

drop if v1_7d == "  "
drop if v0_3_micro == " "

destring v0_3_micro, replace
destring v1_7d, replace

foreach var in v3_3 v4_49 v0_5 cittad v1_7d scuola_pubblica v0_3_micro v1_1 v0_8 v1_3 v6_5 v6_10 {
	tab `var'
}


// Perform transformations
*enrollment to university
tab v3_3
gen uni_ins = .
replace uni_ins = 0 if v3_3 == 2
replace uni_ins = 1 if v3_3 == 1 
*working or not in 2012
tab v4_49
gen work2012 = .
replace work2012 = 0 if v4_49 == 2
replace work2012 = 1 if v4_49 == 1 
*gender
tab v0_5
gen female = .
replace female = 0 if v0_5 == 1
replace female = 1 if v0_5 == 2
*nationality
tab cittad
gen italian = .
replace italian = 0 if cittad == 2
replace italian = 1 if cittad == 1
*level of satisfaction reported by the students
tab v1_7d
sum v1_7d, detail
gen hs_satisfied = 0
replace hs_satisfied = 1 if v1_7d>=8 // We chose 8 as the threshold so as to have the most even split possible (42.44% satisfied, 47.56% not). Results are robust to changen the definition of this variable to equal or higher than 7.
*public school
rename scuola_pubblica public_school
*type of high school
tab v0_3_micro
gen hs_professionali = 0
replace hs_professionali = 1 if v0_3_micro == 1 
gen hs_tecnici = 0
replace hs_tecnici = 1 if v0_3_micro == 2
gen hs_liceo = 0
replace hs_liceo = 1 if inlist(v0_3_micro,3,4,5,6,7)
*If ever changed type of high school
gen changed_hs = 0
replace changed_hs = 1 if v1_1 == 1 
*graduating grade
rename v0_8 grade
*if ever failed a subject
gen ever_failed=0
replace ever_failed=1 if v1_3==1
*father education variables
tab v6_5
gen father_elementary=0
replace father_elementary=1 if v6_5==1
gen father_middle=0
replace father_middle=1 if v6_5==2
gen father_hs=0
replace father_hs=1 if v6_5==3
gen father_uni=0
replace father_uni=1 if v6_5==4
gen father_postgrad=0
replace father_postgrad=1 if v6_5==5	
drop if v6_5==6 //drop because this correspond to "Don't know" answers
sum father*
*mother education variables
tab v6_10
gen mother_elementary=0
replace mother_elementary=1 if v6_10==1
gen mother_middle=0
replace mother_middle=1 if v6_10==2
gen mother_hs=0
replace mother_hs=1 if v6_10==3
gen mother_uni=0
replace mother_uni=1 if v6_10==4
gen mother_postgrad=0
replace mother_postgrad=1 if v6_10==5	
drop if v6_10==6 //drop because this correspond to "Don't know" answers
sum mother*



/*
Description of the final variables:
-uni_ins: 1 if student has enrolled in university after hisgh school, 0 if not
-work2012: 1 if student was working in 2012 (year after graduating high school), 0 if not
-hs_satisfied: 1 if student reported a level of satisfaction with high school of 8 or higher in a 1-10 scale, 0 of 7 or lower. We chose 8 as the threshold so as to have the most even split possible (42.44% satisfied, 47.56% not)
-female: 1 if student is female, 0 if male
-italian: 1 if student is italian, 0 if not
-public_school: 1 if student attended publici school, 0 otherwise
-Type of high school
	-hs_professionali: 1 if student attended "Istituti professionali", 0 otherwise
	-hs_tecnici: 1 if  tudent attended "Istituti tecnici", 0 otherwise
	-hs_liceo: 1 if student attended any type of "Liceo", 0 otherwise
-changed_hs: 1 if student ever changes type of high school.
-grade: graduation grade of the student.
-ever_failed: 1 if student has ever failed a subkect in high school, 0 if not.
-mother's and father's education level: dummies for the highest education levelsof the parents: elementary school, middle school, high school, university and post graduate studies. High school is omitted to avoid colinearity and used as base level.


Summary statistics:
Our final sample is made of 22787 students.
*/
sum uni_ins work2012 hs_satisfied female italian public_school hs_professionali hs_tecnici hs_liceo changed_hs grade ever_failed mother* father*


drop mother_hs father_hs hs_liceo //drop one category to avoid collinearity in the regressions, these levels become the base category of the model.

save "final_data.dta"

***********************************************

***********************************************
/*
3.- Model

3.1.- Separate estimation
We start by modelling both the probablity of going to university and the probability of starting to work after graduation separately.

We model them through with a probit model following the following equations:

uni_ins = hs_satisfied + public_school + hs_professionali + hs_tecnici + father study level dummies (except high school) + mother study level dummies (except high school) + female + italian + error_1

work2012 = hs_satisfied + public_school + hs_professionali + hs_tecnici + father study level dummies (except high school) + mother study level dummies (except high school) + female + italian + error_2
*/
global firsteq "hs_satisfied public_school hs_professionali hs_tecnici father* mother* female italian"
global secondeq "hs_satisfied public_school hs_professionali hs_tecnici father* mother* female italian"

probit uni_ins $firsteq, robust
margins, dydx(hs_satisfied) 

probit work2012 $secondeq, robust
margins, dydx(hs_satisfied)
/*
We report the marginal effects. We focus on the one corresponfing to hs_satisfied, the chnage in the probability of going to university (and starting to work) after high school, from a student who is not satisfied and one who is.

A student being staisfied increases the probability of going to university by 2.11 percentage points. This effect is significant as its p-value is close to zero.

On the probability of working after high school, the effect is negative but not significant.

*/

/*
3.2.- Joint model
However, it makes sense to think that both variables are related (see the freuqnecies and corelation below).
*/
tab uni_ins work2012
corr uni_ins work2012

/*
For this reason, next we propose a biprobit moodel to jointly estimate both probabilities. The equations for each probability are the same proposed above.
*/

global firsteq "hs_satisfied public_school hs_professionali hs_tecnici father* mother* female italian"
global secondeq "hs_satisfied public_school hs_professionali hs_tecnici father* mother* female italian"

biprobit (uni_ins = $firsteq ) (work2012=$secondeq ), robust
margins, dydx(hs_satisfied) predict(pmarg1) //on uni_ins
margins, dydx(hs_satisfied) predict(pmarg2) //on work2022

/*
The value the estimated correlation coefficient (rho) represents the correlation between the error terms in the two equations. A negative rho suggests a negative correlation, meaning that the two outcomes, uni_ins and work2012, are inversely related. Students who are more likely to go to university are less likely to start working immediately after high school, as intuition suggests.

This correlation is significant, so there is evidence to suggest that there is a meaningful negative correlation between the two outcomes. This confirms that modelling both probabilities together does indeed makes sense.

We now proceed to estimate and comment the marginal effect of high school satisfaction on these probabilities.
*/

/*
The marginal effect of hs_satisfied for both uni_ins and work2012 is almost identical to when we modeled both probabilities separately. The effect on uni_ins is still positive and significant (now 2.14 percentage points, before 2.11), and the effect on work2012 is still negative but not statistically significant.
*/
/*
Until now, both models provide strong evidence that a higher level of satisfaction with high school significantly increases the probability of a student going to university. 
*/

/*
3.3. Endogeneity of high school satisfaction

Another problem we encounter, is that these estimates could be biased since we believe that high school satisfaction is endogenous when modelling the 2 variables mentioned aboved. This belief is based on the intuition that many characteristics that make a student be more satisfied with high school (e.g., skill and preferences towards studying and leisure) will make it more prone to keep studying after graduation and less likely that he or she will start working right after graduation, and viceversa. To solve this, we also model high school satisfaction and we use ever_failed, changed_hs and grade as instruments for high school satisfaction.

As stated before, we propose a trivariate probit model. The equations for uni_ins and work2012 are the same as above, and that of hs_satsifaction is the following:

hs_satisfied = ever_failed + changed_hs + grade + hs_satisfied + public_school + hs_professionali + hs_tecnici + father study level dummies (except high school) + mother study level dummies (except high school) + female + italian + error_3
*/

//model
global firsteq "hs_satisfied public_school hs_professionali hs_tecnici father* mother* female italian"
global secondeq "hs_satisfied public_school hs_professionali hs_tecnici father* mother* female italian"
global thirdeq "ever_failed changed_hs public_school grade hs_professionali hs_tecnici father* mother* female italian"

mvprobit (uni_ins = $firsteq ) (work2012=$secondeq ) (hs_satisfied=$thirdeq ), robust draws(1500) seed(683)
estimates store main_model
/*
As in the biprobit model, rho21 is negative and significant, signalling the negative relation between uni_ins and work2012.

The significant correlations between the residuals of high school satisfaction and those of the first two equations (rho31 and rho32) provide evidence of endogeneity, indicating that high school satisfaction is influenced by the same factors that affect university enrollment and starting to work after high school. These results highlight the need to account for this endogeneity when analyzing the relationships between these variables, and support the use of a trivariate probit.
*/

//marginal effect of hs_satisfied
cap preserve 
estimates restore main_model
replace hs_satisfied=1
mvppred pred_xb, xb
replace hs_satisfied=0
mvppred pred_xb_, xb

di pred_xb1
di pred_xb_1

//marginal effect of high school satisfaction on prob(uni_ins)
cap gen APE_hssat_uni=normal(pred_xb1)-normal(pred_xb_1)
bootstrap r(mean), seed(683) reps(1000): sum APE_hssat_uni

//marginal effect of high school satisfaction on prob(work2012)
cap gen APE_hssat_work=normal(pred_xb2)-normal(pred_xb_2)
bootstrap Mean=r(mean), seed(683) reps(1000): sum APE_hssat_work
cap restore

/*
Now the marginal effects of being satisfied in high school have become much larger in magnitude, and more significant.

The effect on the probability of working after high school is now significant, which was not the case before.
*/

/*
These results indicate that high school satisfaction plays a significant role in influencing the choices of students regarding university enrollment and immediate entry into the workforce. Higher satisfaction with high school is associated with a higher likelihood of going to university and a lower likelihood of starting to work after high school.
*/

/*
Results of the trivariate model are robust to changing the threshold of high school satisfaction from higher or equal than 8 to higher or equal than 7.
*/
***********************************************

***********************************************

**

capture log close
log using "heterogeneous effects", replace

//starting the timer
scalar t1 = c(current_time)

//#HETEROGENOUS EFFECTS

global firsteq "hs_satisfied public_school hs_professionali hs_tecnici father* mother* female italian"
global secondeq "hs_satisfied public_school hs_professionali hs_tecnici father* mother* female italian"
global thirdeq "ever_failed changed_hs public_school grade hs_professionali hs_tecnici father* mother* female italian"

//SEX OF THE STUDENT

//Women
use "final_data.dta", clear

keep if female == 1

mvprobit (uni_ins = $firsteq ) (work2012=$secondeq ) (hs_satisfied=$thirdeq ), robust draws(1000) seed(683)

//marginal effect of hs_satisfied
replace hs_satisfied=1
mvppred pred_xb, xb
replace hs_satisfied=0
mvppred pred_xb_, xb

//probabilities
gen p_uni1 = normal(pred_xb1)
gen p_uni0 = normal(pred_xb_1)
sum p_uni0 p_uni1

gen p_work1 = normal(pred_xb2)
gen p_work0 = normal(pred_xb_2)
sum p_work0 p_work1

//marginal effect of high school satisfaction on prob(uni_ins)
gen APE_hssat_uni=normal(pred_xb1)-normal(pred_xb_1)
bootstrap r(mean), seed(683) reps(1000): sum APE_hssat_uni

//marginal effect of high school satisfaction on prob(work2012)
gen APE_hssat_work=normal(pred_xb2)-normal(pred_xb_2)
bootstrap r(mean), seed(683) reps(1000): sum APE_hssat_work


//Men
use "final_data.dta", clear

keep if female == 0

mvprobit (uni_ins = $firsteq ) (work2012=$secondeq ) (hs_satisfied=$thirdeq ), robust draws(1000) seed(683)

//marginal effect of hs_satisfied
replace hs_satisfied=1
mvppred pred_xb, xb
replace hs_satisfied=0
mvppred pred_xb_, xb

//probabilities
gen p_uni1 = normal(pred_xb1)
gen p_uni0 = normal(pred_xb_1)
sum p_uni0 p_uni1

gen p_work1 = normal(pred_xb2)
gen p_work0 = normal(pred_xb_2)
sum p_work0 p_work1

//marginal effect of high school satisfaction on prob(uni_ins)
gen APE_hssat_uni=normal(pred_xb1)-normal(pred_xb_1)
bootstrap r(mean), seed(683) reps(1000): sum APE_hssat_uni

//marginal effect of high school satisfaction on prob(work2012)
gen APE_hssat_work=normal(pred_xb2)-normal(pred_xb_2)
bootstrap r(mean), seed(683) reps(1000): sum APE_hssat_work



//PARENTS EDUCATION
use "final_data.dta", clear

keep if father_uni == 1 | father_postgrad == 1
keep if mother_uni == 1 | mother_postgrad == 1

mvprobit (uni_ins = $firsteq ) (work2012=$secondeq ) (hs_satisfied=$thirdeq ), robust draws(1000) seed(683)

//marginal effect of hs_satisfied
replace hs_satisfied=1
mvppred pred_xb, xb
replace hs_satisfied=0
mvppred pred_xb_, xb

//probabilities
gen p_uni1 = normal(pred_xb1)
gen p_uni0 = normal(pred_xb_1)
sum p_uni0 p_uni1

gen p_work1 = normal(pred_xb2)
gen p_work0 = normal(pred_xb_2)
sum p_work0 p_work1

//marginal effect of high school satisfaction on prob(uni_ins)
gen APE_hssat_uni=normal(pred_xb1)-normal(pred_xb_1)
bootstrap r(mean), seed(683) reps(1000): sum APE_hssat_uni

//marginal effect of high school satisfaction on prob(work2012)
gen APE_hssat_work=normal(pred_xb2)-normal(pred_xb_2)
bootstrap r(mean), seed(683) reps(1000): sum APE_hssat_work


// At least one of the parents has lower than university education.
use "final_data.dta", clear
drop if (father_uni == 1 & mother_uni == 1) | (father_uni == 1 & mother_postgrad == 1) | (father_postgrad == 1 & mother_uni == 1) | (father_postgrad == 1 & mother_postgrad == 1)

mvprobit (uni_ins = $firsteq ) (work2012=$secondeq ) (hs_satisfied=$thirdeq ), robust draws(1000) seed(683)

//marginal effect of hs_satisfied
replace hs_satisfied=1
mvppred pred_xb, xb
replace hs_satisfied=0
mvppred pred_xb_, xb

//probabilities
gen p_uni1 = normal(pred_xb1)
gen p_uni0 = normal(pred_xb_1)
sum p_uni0 p_uni1

gen p_work1 = normal(pred_xb2)
gen p_work0 = normal(pred_xb_2)
sum p_work0 p_work1

//marginal effect of high school satisfaction on prob(uni_ins)
gen APE_hssat_uni=normal(pred_xb1)-normal(pred_xb_1)
bootstrap r(mean), seed(683) reps(1000): sum APE_hssat_uni

//marginal effect of high school satisfaction on prob(work2012)
gen APE_hssat_work=normal(pred_xb2)-normal(pred_xb_2)
bootstrap r(mean), seed(683) reps(1000): sum APE_hssat_work



//TYPE OF HS
//liceo
use "final_data.dta", clear

keep if hs_tecnici == 0 & hs_professionali == 0

mvprobit (uni_ins = $firsteq ) (work2012=$secondeq ) (hs_satisfied=$thirdeq ), robust draws(1000) seed(683)

//marginal effect of hs_satisfied
replace hs_satisfied=1
mvppred pred_xb, xb
replace hs_satisfied=0
mvppred pred_xb_, xb

//probabilities
gen p_uni1 = normal(pred_xb1)
gen p_uni0 = normal(pred_xb_1)
sum p_uni0 p_uni1

gen p_work1 = normal(pred_xb2)
gen p_work0 = normal(pred_xb_2)
sum p_work0 p_work1

//marginal effect of high school satisfaction on prob(uni_ins)
gen APE_hssat_uni=normal(pred_xb1)-normal(pred_xb_1)
bootstrap r(mean), seed(683) reps(1000): sum APE_hssat_uni

//marginal effect of high school satisfaction on prob(work2012)
gen APE_hssat_work=normal(pred_xb2)-normal(pred_xb_2)
bootstrap r(mean), seed(683) reps(1000): sum APE_hssat_work


//hs tecnico
use "final_data.dta", clear

keep if hs_tecnici == 1

mvprobit (uni_ins = $firsteq ) (work2012=$secondeq ) (hs_satisfied=$thirdeq ), robust draws(1000) seed(683)

//marginal effect of hs_satisfied
replace hs_satisfied=1
mvppred pred_xb, xb
replace hs_satisfied=0
mvppred pred_xb_, xb

//probabilities
gen p_uni1 = normal(pred_xb1)
gen p_uni0 = normal(pred_xb_1)
sum p_uni0 p_uni1

gen p_work1 = normal(pred_xb2)
gen p_work0 = normal(pred_xb_2)
sum p_work0 p_work1

//marginal effect of high school satisfaction on prob(uni_ins)
gen APE_hssat_uni=normal(pred_xb1)-normal(pred_xb_1)
bootstrap r(mean), seed(683) reps(1000): sum APE_hssat_uni

//marginal effect of high school satisfaction on prob(work2012)
gen APE_hssat_work=normal(pred_xb2)-normal(pred_xb_2)
bootstrap r(mean), seed(683) reps(1000): sum APE_hssat_work


//hs professionali
use "final_data.dta", clear

keep if hs_professionali == 1

mvprobit (uni_ins = $firsteq ) (work2012=$secondeq ) (hs_satisfied=$thirdeq ), robust draws(1000) seed(683)

//marginal effect of hs_satisfied
replace hs_satisfied=1
mvppred pred_xb, xb
replace hs_satisfied=0
mvppred pred_xb_, xb

//probabilities
gen p_uni1 = normal(pred_xb1)
gen p_uni0 = normal(pred_xb_1)
sum p_uni0 p_uni1

gen p_work1 = normal(pred_xb2)
gen p_work0 = normal(pred_xb_2)
sum p_work0 p_work1

//marginal effect of high school satisfaction on prob(uni_ins)
gen APE_hssat_uni=normal(pred_xb1)-normal(pred_xb_1)
bootstrap r(mean), seed(683) reps(1000): sum APE_hssat_uni

//marginal effect of high school satisfaction on prob(work2012)
gen APE_hssat_work=normal(pred_xb2)-normal(pred_xb_2)
bootstrap r(mean), seed(683) reps(1000): sum APE_hssat_work

//timer
scalar t2 = c(current_time)
display (clock(t2, "hms") - clock(t1, "hms")) / 1000 " seconds"

log close
translate "heterogeneous effects.smcl" "heterogeneous effects.pdf", translator(smcl2pdf)

/*
4.- PEA
*/

estimates restore main_model

//gender effect
*female
scalar pr_f_l_phs_0=normal(e(b)[1,1]*0+e(b)[1,13]+e(b)[1,14]+e(b)[1,2]+e(b)[1,15]) 
di pr_f_l_phs_0
scalar pr_f_l_phs_1=normal(e(b)[1,1]*1+e(b)[1,13]+e(b)[1,14]+e(b)[1,2]+e(b)[1,15]) 
di pr_f_l_phs_1
scalar PEA_f_l_phs=pr_f_l_phs_1-pr_f_l_phs_0
di PEA_f_l_phs
*male
scalar pr_m_l_phs_0=normal(e(b)[1,1]*0+e(b)[1,14]+e(b)[1,2]+e(b)[1,15]) 
di pr_m_l_phs_0
scalar pr_m_l_phs_1=normal(e(b)[1,1]*1+e(b)[1,14]+e(b)[1,2]+e(b)[1,15]) 
di pr_m_l_phs_1
scalar PEA_m_l_phs=pr_m_l_phs_1-pr_m_l_phs_0
di PEA_m_l_phs

//high school type effect
*female
*liceo
scalar pr_f_l_phs_0=normal(e(b)[1,1]*0+e(b)[1,13]+e(b)[1,14]+e(b)[1,2]+e(b)[1,15]) 
di pr_f_l_phs_0
scalar pr_f_l_phs_1=normal(e(b)[1,1]*1+e(b)[1,13]+e(b)[1,14]+e(b)[1,2]+e(b)[1,15]) 
di pr_f_l_phs_1
scalar PEA_f_l_phs=pr_f_l_phs_1-pr_f_l_phs_0
di PEA_f_l_phs
*tecnico
scalar pr_f_t_phs_0=normal(e(b)[1,1]*0+e(b)[1,13]+e(b)[1,14]+e(b)[1,2]+e(b)[1,15]+e(b)[1,4]) 
di pr_f_t_phs_0
scalar pr_f_t_phs_1=normal(e(b)[1,1]*1+e(b)[1,13]+e(b)[1,14]+e(b)[1,2]+e(b)[1,15]+e(b)[1,4]) 
di pr_f_t_phs_1
scalar PEA_f_t_phs=pr_f_t_phs_1-pr_f_t_phs_0
di PEA_f_t_phs
*professionale
scalar pr_f_p_phs_0=normal(e(b)[1,1]*0+e(b)[1,13]+e(b)[1,14]+e(b)[1,2]+e(b)[1,15]+e(b)[1,3]) 
di pr_f_p_phs_0
scalar pr_f_p_phs_1=normal(e(b)[1,1]*1+e(b)[1,13]+e(b)[1,14]+e(b)[1,2]+e(b)[1,15]+e(b)[1,3]) 
di pr_f_p_phs_1
scalar PEA_f_p_phs=pr_f_p_phs_1-pr_f_p_phs_0
di PEA_f_p_phs

*male
*liceo
scalar pr_m_l_phs_0=normal(e(b)[1,1]*0+e(b)[1,14]+e(b)[1,2]+e(b)[1,15]) 
di pr_m_l_phs_0
scalar pr_m_l_phs_1=normal(e(b)[1,1]*1+e(b)[1,14]+e(b)[1,2]+e(b)[1,15]) 
di pr_m_l_phs_1
scalar PEA_m_l_phs=pr_m_l_phs_1-pr_m_l_phs_0
di PEA_m_l_phs
*tecnico
scalar pr_m_t_phs_0=normal(e(b)[1,1]*0+e(b)[1,14]+e(b)[1,2]+e(b)[1,15]+e(b)[1,4]) 
di pr_m_t_phs_0
scalar pr_m_t_phs_1=normal(e(b)[1,1]*1+e(b)[1,14]+e(b)[1,2]+e(b)[1,15]+e(b)[1,4]) 
di pr_m_t_phs_1
scalar PEA_m_t_phs=pr_m_t_phs_1-pr_m_t_phs_0
di PEA_m_t_phs
*professionale
scalar pr_m_p_phs_0=normal(e(b)[1,1]*0+e(b)[1,14]+e(b)[1,2]+e(b)[1,15]+e(b)[1,3]) 
di pr_m_p_phs_0
scalar pr_m_p_phs_1=normal(e(b)[1,1]*1+e(b)[1,14]+e(b)[1,2]+e(b)[1,15]+e(b)[1,3]) 
di pr_m_p_phs_1
scalar PEA_m_p_phs=pr_m_p_phs_1-pr_m_p_phs_0
di PEA_m_p_phs

//parents education effect
*female
*both high school
scalar pr_f_l_phs_0=normal(e(b)[1,1]*0+e(b)[1,13]+e(b)[1,14]+e(b)[1,2]+e(b)[1,15]) 
di pr_f_l_phs_0
scalar pr_f_l_phs_1=normal(e(b)[1,1]*1+e(b)[1,13]+e(b)[1,14]+e(b)[1,2]+e(b)[1,15]) 
di pr_f_l_phs_1
scalar PEA_f_l_phs=pr_f_l_phs_1-pr_f_l_phs_0
di PEA_f_l_phs
*both university
scalar pr_f_l_pu_0=normal(e(b)[1,1]*0+e(b)[1,13]+e(b)[1,14]+e(b)[1,2]+e(b)[1,15]+e(b)[1,7]+e(b)[1,11]) 
di pr_f_l_pu_0
scalar pr_f_l_pu_1=normal(e(b)[1,1]*1+e(b)[1,13]+e(b)[1,14]+e(b)[1,2]+e(b)[1,15]+e(b)[1,7]+e(b)[1,11]) 
di pr_f_l_pu_1
scalar PEA_f_l_pu=pr_f_l_pu_1-pr_f_l_pu_0
di PEA_f_l_pu

*male
*both high school
scalar pr_m_l_phs_0=normal(e(b)[1,1]*0+e(b)[1,14]+e(b)[1,2]+e(b)[1,15]) 
di pr_m_l_phs_0
scalar pr_m_l_phs_1=normal(e(b)[1,1]*1+e(b)[1,14]+e(b)[1,2]+e(b)[1,15]) 
di pr_m_l_phs_1
scalar PEA_m_l_phs=pr_m_l_phs_1-pr_m_l_phs_0
di PEA_m_l_phs
*both university
scalar pr_m_l_pu_0=normal(e(b)[1,1]*0+e(b)[1,14]+e(b)[1,2]+e(b)[1,15]+e(b)[1,7]+e(b)[1,11]) 
di pr_m_l_pu_0
scalar pr_m_l_pu_1=normal(e(b)[1,1]*1+e(b)[1,14]+e(b)[1,2]+e(b)[1,15]+e(b)[1,7]+e(b)[1,11]) 
di pr_m_l_pu_1
scalar PEA_m_l_pu=pr_m_l_pu_1-pr_m_l_pu_0
di PEA_m_l_pu

log close
translate "New data application - Advanced Microeconometrics.smcl" "New data application - Advanced Microeconometrics.pdf", translator(smcl2pdf)

scalar t2 = c(current_time)
display (clock(t2, "hms") - clock(t1, "hms")) / 1000 " seconds"

//with 500 simulations APE = .4701373 
//with 1000 simultaions APE = .4704358
//with 1500 simulations APE = .4706483
