**************************************************************
* PAPER:  Does Antenatal Care Visit Mediate or Moderate the 
* Association between IPV and Access to Skilled Birth Attendant?

* Among Women of Reproductive Age in Sub-saharan Africa (SSA):
* A Cross-National Mediation and Moderation Analysis
*
* Author: David A. Okunlola 
* Data: DHS Pooled 23 coutries in sub-Saharan Africa 
* Date: June 2026
**************************************************************

**************************************************************
* SECTION 0: SETUP
**************************************************************

clear all
set more off
set maxvar 120000
capture log close
*log using "PAPER1_ANALYSIS_LOG.log", replace

* Install required packages if needed
capture ssc install outreg2    // for regression tables
capture ssc install fre      // for tabulation
capture ssc install tablbl   // for crosstabs
capture ssc install grc1leg2   // for combining graphs
capture ssc install tabout   // for exporting tables


cd "C:\Users\Daves\OneDrive - Florida State University\Dr Davis SSA Lab\DHS Data and Dofile"

use "AOIR81FL.dta", clear
append using BJIR71FL
append using CDIR81FL
append using CMIR71FL
append using ETIR81FL
append using GNIR71FL
append using MDIR81FL
append using MLIR8AFL
append using MZIR81FL
append using NGIR8BFL
append using AOIR81FL
append using BFIR81FL
append using BUIR71FL
append using TDIR71FL
append using KMIR61FL
append using CGIR61FL
append using CIIR81FL
append using szir51fl
append using GAIR71FL
append using GMIR81FL
append using GHIR8CFL
append using KEIR8CFL
append using LSIR81FL
append using LBIR7AFL
append using MWIR81FL
append using NMIR61FL
append using NIIR61FL
append using RWIR81FL
append using STIR51FL
append using SNIR8SFL
append using SLIR7AFL
append using ZAIR71FL
append using TZIR82FL
append using TGIR61FL
append using UGIR7BFL
append using ZMIR81FL
append using ZWIR72FL

save "POOLED_10COUNTRY_DV.dta", replace 

use POOLED_10COUNTRY_DV, clear

**************************************************************
* SECTION 1:
**************************************************************
****Generating weight***** using the hiv-survey weight because hiv prevalence is the outcome of interest
gen wt = v005 / 1000000
egen pooled_cluster = group(v000 v001), label
egen pooled_strata = group(v000 v023), label
svyset pooled_cluster [pweight=wt], strata(pooled_strata) singleunit(centered)

* Overall N by country
fre v000
encode v000, gen(country)
fre country

la def country ///
1 "Angola" 2 "Burkina Faso" 3 "Benin" 4 "Burundi" 5 "DR Congo" ///
6 "Congo" 7 "Cote d'Ivoire" 8 "Cameroon" 9 "Ethiopia" 10 "Gabon" ///
11 "Ghana" 12 "Gambia" 13 "Guinea" 14 "Kenya" 15 "Comoros" ///
16 "Liberia" 17 "Lesotho" 18 "Madagascar" 19 "Mali" 20 "Malawi" ///
21 "Mozambique" 22 "Nigeria" 23 "Niger" 24 "Namibia" 25 "Rwanda" ///
26 "Sierra Leone" 27 "Senegal" 28 "Sao Tome and Principe" 29 "Eswatini" 30 "Chad" ///
31 "Togo" 32 "Tanzania" 33 "Uganda" 34 "South Africa" 35 "Zambia" ///
36 "Zimbabwe", modify

la val country country
fre country [iw=wt]

**Children ever born
fre v201
recode v201 (0=0 "Childless")(1/21=1 "Non-childless")(else=.), gen(fertility)
fre fertility

**Age
fre v012
clonevar age = v012

**Education
fre v133
clonevar edu = v133
replace edu =. if v133 > 25
fre edu 

**Wealth quintiles
fre v190
clonevar wealth = v190
fre wealth

***Checking available variables by country
local vars fertility age edu wealth 

* keep only variables that actually exist; flag any that don't
local ok ""
foreach v of local vars {
    capture confirm variable `v'
    if _rc di as error "Not in dataset: `v'"
    else   local ok `ok' `v'
}

* rows = country, columns = variable, cell = # of non-missing obs (0 = absent)
tabstat `ok', by(country) statistics(n) columns(variables) nototal

**Missing data exploration
egen nmiss = rowmiss(fertility age edu wealth)
ta nmiss

**Target sample
gen pop = age==15
ta pop
 
***Declare weight
svyset pooled_cluster [pweight=wt], strata(pooled_strata) singleunit(centered)

**OLS
svy,subpop(pop): reg fertility edu i.wealth
outreg2 using "reg.doc", stats(coef ci) noobs addstat("Prob > F", e(p), "N (subpop)", e(N_subpop)) dec(2) title("Table: Using svy,subpop") ctitle("OLS") replace 
**Poisson
svy,subpop(pop): poisson fertility edu i.wealth
outreg2 using "reg.doc", stats(coef ci) noobs addstat("Prob > F", e(p), "N (subpop)", e(N_subpop)) dec(2) ctitle("Poisson") append 
**Logistic
svy,subpop(pop): logistic fertility edu i.wealth 
outreg2 using "reg.doc", stats(coef ci) noobs addstat("Prob > F", e(p), "N (subpop)", e(N_subpop)) dec(2) ctitle("Logistic") append 

***Random Intercept model
***Assuming cluster weight = 1
gen wt2 = 1
**Decleare multilevel weight
svyset pooled_cluster, weight(wt2) strata(pooled_strata) ///
    singleunit(centered) || _n, weight(wt)

svy,subpop(pop): melogit fertility edu i.wealth || pooled_cluster:
outreg2 using "reg.doc", stats(coef ci) noobs addstat("Prob > F", e(p), "N (subpop)", e(N_subpop)) dec(2) ctitle("Random Intercept Logistic") append 


***Testing SVYSLIM
*==================================================================*
* Across Countries in Africa: Single level models
*==================================================================*
preserve
svyset pooled_cluster [pweight=wt], strata(pooled_strata) singleunit(centered)   // declare survey data
**Keep variables
svyslim pop, complete(fertility edu wealth)       // shrinks to subpop
save subpop_slim, replace                // 25,215 rows out of 539,883

* ---- FROM NOW ON (fast, small file) ----
use subpop_slim, clear
**OLS
svy,subpop(pop): reg fertility edu i.wealth
outreg2 using "regg.doc", stats(coef ci) noobs addstat("Prob > F", e(p), "N (subpop)", e(N_subpop)) dec(2) title("Table: Using svyslim") ctitle("OLS") replace 
**Poisson
svy,subpop(pop): poisson fertility edu i.wealth
outreg2 using "regg.doc", stats(coef ci) noobs addstat("Prob > F", e(p), "N (subpop)", e(N_subpop)) dec(2) ctitle("Poisson") append 
**Logistic
svy,subpop(pop): logistic fertility edu i.wealth 
outreg2 using "regg.doc", stats(coef ci) noobs addstat("Prob > F", e(p), "N (subpop)", e(N_subpop)) dec(2) ctitle("Logistic") append 
restore

***Random Intercept model
preserve
***Assuming cluster weight = 1
gen wt_2 = 1
**Decleare multilevel weight
svyset pooled_cluster, weight(wt_2) strata(pooled_strata) ///
    singleunit(centered) || _n, weight(wt)
**Keep variables
svyslim pop, complete(fertility edu wealth) pweight(wt)       // shrinks to subpop
save subpop_slimm, replace                // 25,215 rows out of 539,883
use subpop_slimm, clear
***Random intercept regression
svy,subpop(pop): melogit fertility edu i.wealth || pooled_cluster:
outreg2 using "regg.doc", stats(coef ci) noobs addstat("Prob > F", e(p), "N *(subpop)", e(N_subpop)) dec(2) ctitle("Random Intercept Logistic") append 
restore




