*==================================================================*
* svyslim_verify.do      run:  do svyslim_verify.do
* Proves that, after svyslim, running  svy, subpop(grp): MODEL  on the
* small slimmed dataset reproduces the FULL-DATA  svy, subpop(grp)
* result (coefficients AND standard errors) essentially exactly, for
* every model -- while keeping only the subpop rows + a few markers.
*==================================================================*
clear all
set seed 20260628

* --- make sure Stata can find svyslim.ado (cd here first if needed) ---
adopath + "`c(pwd)'"
capture which svyslim
if _rc {
    di as err "svyslim.ado not found. In Stata:  cd into its folder, then rerun."
    exit 199
}
discard

*------------------------------------------------------------------*
* tiny helpers
*------------------------------------------------------------------*
capture program drop _gb
program define _gb
    args cf pre
    scalar `pre'_b  = _b[`cf']
    scalar `pre'_se = _se[`cf']
    scalar `pre'_df = e(df_r)
end
capture program drop _cmp
program define _cmp
    args name cf
    di as txt _n "  " as res "`name'" as txt "  [coef `cf']"
    di as txt "     full  svy,subpop : b=" as res %11.6f scalar(fu_b) ///
       as txt "  se=" as res %10.6f scalar(fu_se) as txt "  df=" as res scalar(fu_df)
    di as txt "     svyslim + subpop : b=" as res %11.6f scalar(sl_b) ///
       as txt "  se=" as res %10.6f scalar(sl_se) as txt "  df=" as res scalar(sl_df)
    di as txt "     |b diff| = " as res %9.2e abs(scalar(fu_b)-scalar(sl_b)) ///
       as txt "     |se diff| = " as res %9.2e abs(scalar(fu_se)-scalar(sl_se))
end

*------------------------------------------------------------------*
* build complex-survey data: subpop ABSENT from some whole PSUs
*------------------------------------------------------------------*
local H 60
local Cper 4
local nper 200
set obs `=`H'*`Cper'*`nper''
gen long strat = ceil(_n/(`Cper'*`nper'))
gen long psu   = ceil(_n/`nper')
bysort psu (strat): gen double u = rnormal() if _n==1
bysort psu (strat): replace u = u[1]
bysort psu (strat): gen double pu = runiform() if _n==1
bysort psu (strat): replace pu = pu[1]
gen byte psu_has = pu < 0.70
gen double x1 = rnormal()
gen double x2 = rnormal()*0.5 + 0.3*x1
gen byte grp = (runiform() < 0.6) & psu_has
gen double wt = exp(0.25*x1)
sum wt, meanonly
replace wt = wt/r(mean)
gen double xb = -0.2 + 0.5*x1 - 0.3*x2 + 0.7*u
gen byte   ybin   = runiform() < invlogit(xb)
gen double ycont  = xb + rnormal()
gen long   ycount = rpoisson(exp(0.2 + 0.4*x1 - 0.2*x2 + 0.5*u))
gen double gmean  = exp(0.2 + 0.4*x1 - 0.2*x2 + 0.5*u)
gen long   ycnb   = rpoisson(gmean*rgamma(0.7,1/0.7))
gen double e1     = xb + rlogistic()
gen byte   ycat   = 1 + (e1 > -0.4) + (e1 > 0.8)

svyset psu [pw=wt], strata(strat) singleunit(centered)

di as res _n(2) "######## svyslim vs full-data svy, subpop() ########"

*------------------- LOGIT (+ show the data reduction) -------------*
svy, subpop(grp): logit ybin x1 x2
_gb x1 fu
preserve
    svyslim grp, complete(ybin x1 x2)
    local kept = r(N_kept)
    local full = r(N_full)
    svy, subpop(grp): logit ybin x1 x2
    _gb x1 sl
restore
_cmp "LOGIT" "x1"
di as txt "     data reduced from " as res `full' as txt " rows to " as res `kept' as txt " rows."

*------------------- REGRESS --------------------------------------*
svy, subpop(grp): regress ycont x1 x2
_gb x1 fu
preserve
    svyslim grp, complete(ycont x1 x2)
    svy, subpop(grp): regress ycont x1 x2
    _gb x1 sl
restore
_cmp "REGRESS" "x1"

*------------------- POISSON -------------------------------------*
svy, subpop(grp): poisson ycount x1 x2
_gb x1 fu
preserve
    svyslim grp, complete(ycount x1 x2)
    svy, subpop(grp): poisson ycount x1 x2
    _gb x1 sl
restore
_cmp "POISSON" "x1"

*------------------- NBREG ---------------------------------------*
svy, subpop(grp): nbreg ycnb x1 x2
_gb x1 fu
preserve
    svyslim grp, complete(ycnb x1 x2)
    svy, subpop(grp): nbreg ycnb x1 x2
    _gb x1 sl
restore
_cmp "NBREG" "x1"

*------------------- PROBIT --------------------------------------*
svy, subpop(grp): probit ybin x1 x2
_gb x1 fu
preserve
    svyslim grp, complete(ybin x1 x2)
    svy, subpop(grp): probit ybin x1 x2
    _gb x1 sl
restore
_cmp "PROBIT" "x1"

*------------------- MLOGIT (coef 2:x1) --------------------------*
svy, subpop(grp): mlogit ycat x1 x2, baseoutcome(1)
_gb "2:x1" fu
preserve
    svyslim grp, complete(ycat x1 x2)
    svy, subpop(grp): mlogit ycat x1 x2, baseoutcome(1)
    _gb "2:x1" sl
restore
_cmp "MLOGIT" "2:x1"

*------------------- OLOGIT --------------------------------------*
svy, subpop(grp): ologit ycat x1 x2
_gb x1 fu
preserve
    svyslim grp, complete(ycat x1 x2)
    svy, subpop(grp): ologit ycat x1 x2
    _gb x1 sl
restore
_cmp "OLOGIT" "x1"

*------------------- MEAN ----------------------------------------*
svy, subpop(grp): mean ycont
_gb ycont fu
preserve
    svyslim grp, complete(ycont)
    svy, subpop(grp): mean ycont
    _gb ycont sl
restore
_cmp "MEAN" "ycont"

di as txt _n "If every |b diff| and |se diff| is ~1e-7 or smaller, svyslim"
di as txt "reproduces svy, subpop() exactly on a fraction of the rows."
di as txt _n "WORKFLOW for your real data (run once, then reuse the small file):"
di as txt "   use bigdata, clear"
di as txt "   svyset psu [pw=wt], strata(strat)"
di as txt "   svyslim mysubpop, complete(<all vars you will model>)"
di as txt "   save subpop_slim, replace"
di as txt "   * thereafter, fast:"
di as txt "   use subpop_slim, clear"
di as txt "   svy, subpop(mysubpop): logit y x1 x2 ..."


*==================================================================*
* PART 4 : totals option (Nichols 2007 variant)
* Default (minimal) mode matches b and se but NOT e(N_pop).
* totals mode must match b, se, AND e(N_pop) (population size).
*==================================================================*
di as res _n(2) "############ PART 4: totals option — e(N_pop) ############"
svy, subpop(grp): logit ybin x1 x2
scalar fu_b   = _b[x1]
scalar fu_se  = _se[x1]
scalar fu_np  = e(N_pop)
scalar fu_nsp = e(N_subpop)
preserve
    svyslim grp, complete(ybin x1 x2) totals
    svy, subpop(grp): logit ybin x1 x2
    scalar sl_b   = _b[x1]
    scalar sl_se  = _se[x1]
    scalar sl_np  = e(N_pop)
    scalar sl_nsp = e(N_subpop)
restore
di as txt _n "  LOGIT with svyslim, totals:"
di as txt "     full : b=" as res %11.6f fu_b as txt "  se=" as res %10.6f fu_se ///
   as txt "  N_pop=" as res %14.2f fu_np as txt "  N_subpop=" as res %12.2f fu_nsp
di as txt "     slim : b=" as res %11.6f sl_b as txt "  se=" as res %10.6f sl_se ///
   as txt "  N_pop=" as res %14.2f sl_np as txt "  N_subpop=" as res %12.2f sl_nsp
di as txt "     |b diff| = "  as res %9.2e abs(fu_b-sl_b) ///
   as txt "  |se diff| = "    as res %9.2e abs(fu_se-sl_se)
di as txt "     |N_pop diff| = " as res %9.2e abs(fu_np-sl_np) ///
   as txt "   (all three should be ~0 with the totals option)"


*==================================================================*
* PART 5 : impute option (bad markers repaired by cluster donation)
* Engineered missingness in EMPTY clusters:
*   type A: x2 missing for the WHOLE cluster (no donor possible)
*   type B: rows alternate missing x1 / missing x2 (no single row is
*           complete on the union, but donors exist for each variable)
* Expectations:
*   model ybin x1     -> svyslim,impute matches full data EXACTLY
*                        (type-B clusters are rescued by donation)
*   model ybin x1 x2  -> type-A clusters drop in BOTH runs (match);
*                        type-B clusters are the DOCUMENTED EDGE CASE:
*                        retained in slim, dropped in full -> tiny diff
*==================================================================*
di as res _n(2) "############ PART 5: impute option ############"
preserve

* find empty PSUs and split them into type A / type B
tempvar hp
bysort psu: egen byte `hp' = max(grp)
gen byte _typeA = (`hp'==0) & mod(psu,2)==0
gen byte _typeB = (`hp'==0) & mod(psu,2)==1
replace x2 = . if _typeA
bysort psu (strat): gen long _rn = _n
replace x1 = . if _typeB & mod(_rn,2)==0
replace x2 = . if _typeB & mod(_rn,2)==1
tempfile fulldat
quietly save `fulldat'

* ---------- model ybin x1 : impute should give an EXACT match -------
svy, subpop(grp): logit ybin x1
scalar fu_b  = _b[x1]
scalar fu_se = _se[x1]
use `fulldat', clear
svyslim grp, complete(ybin x1 x2) impute(donor)
svy, subpop(grp): logit ybin x1
di as txt _n "  MODEL ybin x1   (type-B clusters rescued by donation):"
di as txt "     full        : b=" as res %11.6f fu_b  as txt "  se=" as res %10.6f fu_se
di as txt "     slim,impute : b=" as res %11.6f _b[x1] as txt "  se=" as res %10.6f _se[x1]
di as txt "     |b diff| = " as res %9.2e abs(fu_b-_b[x1]) ///
   as txt "  |se diff| = " as res %9.2e abs(fu_se-_se[x1]) as txt "   (expect ~0)"

* same model WITHOUT impute: bad markers may drop, showing the problem
use `fulldat', clear
svyslim grp, complete(ybin x1 x2)
svy, subpop(grp): logit ybin x1
di as txt "     slim,NO impute: b=" as res %11.6f _b[x1] as txt "  se=" as res %10.6f _se[x1]
di as txt "     (a small se difference HERE is the problem impute fixes)"

* ---------- model ybin x1 x2 : the documented edge case -------------
use `fulldat', clear
svy, subpop(grp): logit ybin x1 x2
scalar fu_b  = _b[x1]
scalar fu_se = _se[x1]
use `fulldat', clear
svyslim grp, complete(ybin x1 x2) impute(donor)
svy, subpop(grp): logit ybin x1 x2
di as txt _n "  MODEL ybin x1 x2   (documented edge case):"
di as txt "     full        : b=" as res %11.6f fu_b  as txt "  se=" as res %10.6f fu_se
di as txt "     slim,impute : b=" as res %11.6f _b[x1] as txt "  se=" as res %10.6f _se[x1]
di as txt "     |b diff| = " as res %9.2e abs(fu_b-_b[x1]) ///
   as txt "  |se diff| = " as res %9.2e abs(fu_se-_se[x1])
di as txt "     Type-B clusters are retained here by the composite marker but"
di as txt "     dropped by the full data (no single complete row): a TINY,"
di as txt "     documented divergence. Type-A clusters drop in both (match)."

* ---------- impute(all): always-retain semantics ---------------------
use `fulldat', clear
svyslim grp, complete(ybin x1 x2) impute(all)
svy, subpop(grp): logit ybin x1 x2
di as txt _n "  MODEL ybin x1 x2 with impute(all):"
di as txt "     slim,impute(all): b=" as res %11.6f _b[x1] as txt "  se=" as res %10.6f _se[x1]
di as txt "     impute(all) also fills type-A markers (dataset-minimum fallback),"
di as txt "     so EVERY empty cluster is retained. This is a deliberate design"
di as txt "     choice - 'sampled clusters always count' - and diverges from the"
di as txt "     full-data run wherever full data would drop a cluster entirely."

restore
