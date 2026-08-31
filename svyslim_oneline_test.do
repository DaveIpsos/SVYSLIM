*==================================================================*
* svyslim_oneline_test.do
*   Verifies the NEW one-line (prefix) form of svyslim gives the
*   SAME result as the two-step form and as full-data svy, subpop().
*
*   Run:  do svyslim_oneline_test.do   (svyslim.ado must be found)
*==================================================================*
clear all
set seed 20260722
adopath + "`c(pwd)'"
capture which svyslim
if _rc { di as err "svyslim.ado not found here."; exit 199 }
discard

* small clustered survey with a subpop absent from some PSUs
set obs 40000
gen long psu   = ceil(_n/50)
gen long strat = ceil(psu/4)
bysort psu (strat): gen double u = rnormal() if _n==1
bysort psu (strat): replace u = u[1]
gen double x1 = rnormal()
gen byte female = runiform()<0.5
gen double xb = -0.2 + 0.5*x1 - 0.3*female + 0.5*u
gen byte health = 1 + (runiform()<invlogit(xb)) + (runiform()<invlogit(xb-0.5))
gen byte pop = (runiform()<0.5) & (mod(psu,3)!=0)   // absent from some PSUs
gen double wt = exp(0.25*x1)
sum wt, meanonly
replace wt = wt/r(mean)
svyset psu [pw=wt], strata(strat)

di as res _n "===== A. full-data svy, subpop() ====="
svy, subpop(pop): ologit health x1 i.female
scalar A = _b[x1]

di as res _n "===== B. two-step svyslim ====="
preserve
    svyslim pop, complete(health x1 female)
    svy, subpop(pop): ologit health x1 i.female
    scalar B = _b[x1]
restore

di as res _n "===== C. one-line svyslim (explicit complete) ====="
svyslim pop, complete(health x1 female): ologit health x1 i.female
scalar C = _b[x1]

di as res _n "===== D. one-line svyslim (inferred complete) ====="
svyslim pop: ologit health x1 i.female
scalar D = _b[x1]

di as res _n(2) "================ AGREEMENT ================"
di as txt "x1 coefficient from each route (should be identical):"
di as txt "  A full        = " as res %12.8f A
di as txt "  B two-step    = " as res %12.8f B
di as txt "  C one-line    = " as res %12.8f C
di as txt "  D one-line inf= " as res %12.8f D
di as txt "  max |A - {B,C,D}| = " as res %9.2e ///
    max(abs(A-B),abs(A-C),abs(A-D)) as txt "  (expect ~0)"
di as txt _n "Data still in memory after the one-line runs? rows = " as res _N
di as txt "(should equal the FULL 40,000 - the wrapper restores the data.)"
