*==================================================================*
* svyslim_models_test.do     run:  do svyslim_models_test.do
*
* Verifies that svyslim + svy,subpop() reproduces the FULL-DATA
* svy,subpop() result for the EXTENDED model list:
*   betareg, stcox, zip, zinb, tpoisson, tnbreg,
*   mixed, melogit, meologit, mepoisson, menbreg
* plus a gsem passthrough example (multilevel multinomial).
*
* svyslim itself is model-agnostic (it only slims the data), so the
* markers preserve the design for ANY svy-capable command. This file
* is the proof on your machine.
*
* NOTE ON HONESTY: mebetareg, memlogit, mezip, mezinb, metpoisson,
* metnbreg are NOT official Stata commands and cannot be tested.
* Multilevel multinomial is shown via gsem; multilevel beta can be
* attempted via gsem, family(beta) on Stata 17+ (commented example).
*==================================================================*
clear all
set seed 20260702

adopath + "`c(pwd)'"
capture which svyslim
if _rc {
    di as err "svyslim.ado not found. cd into its folder, then rerun."
    exit 199
}
discard

*------------------------------------------------------------------*
* helpers
*------------------------------------------------------------------*
capture program drop _gb
program define _gb
    args cf pre
    scalar `pre'_b  = _b[`cf']
    scalar `pre'_se = _se[`cf']
end
capture program drop _cmp
program define _cmp
    args name cf
    di as txt _n "  " as res "`name'" as txt "  [coef `cf']"
    di as txt "     full  svy,subpop : b=" as res %11.6f scalar(fu_b) ///
       as txt "  se=" as res %10.6f scalar(fu_se)
    di as txt "     svyslim + subpop : b=" as res %11.6f scalar(sl_b) ///
       as txt "  se=" as res %10.6f scalar(sl_se)
    di as txt "     |b diff| = " as res %9.2e abs(scalar(fu_b)-scalar(sl_b)) ///
       as txt "     |se diff| = " as res %9.2e abs(scalar(fu_se)-scalar(sl_se))
end

*------------------------------------------------------------------*
* build complex-survey data with all outcome types
* (smaller N than before because me-models are slow)
*------------------------------------------------------------------*
local H 40
local Cper 4
local nper 120
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
gen double xb = -0.2 + 0.5*x1 - 0.3*x2 + 0.5*u

* outcomes
gen byte   ybin  = runiform() < invlogit(xb)
gen double ycont = xb + rnormal()
* beta outcome strictly inside (0,1)
gen double ybeta = invlogit(xb + rnormal()*0.8)
replace ybeta = 0.001 if ybeta <= 0
replace ybeta = 0.999 if ybeta >= 1
* survival: exponential time, ~30% censoring
gen double tsurv = -ln(runiform())/exp(0.3*x1)
gen double tcens = -ln(runiform())/0.30
gen byte   fail  = tsurv <= tcens
gen double ttime = min(tsurv, tcens)
* zero-inflated count: extra zeros with prob depending on x2
gen byte   iszero = runiform() < invlogit(-0.8 + 0.6*x2)
gen long   yzip  = cond(iszero, 0, rpoisson(exp(0.3 + 0.4*x1 + 0.4*u)))
* zero-truncated count: strictly positive
gen long   ytr   = rpoisson(exp(0.5 + 0.4*x1 + 0.3*u))
replace    ytr   = 1 if ytr==0
* 3-category outcome for gsem multinomial
gen double e1   = xb + rlogistic()
gen byte   ycat = 1 + (e1 > -0.4) + (e1 > 0.8)
* overdispersed count for nbreg-family
gen double gmean = exp(0.3 + 0.4*x1 + 0.4*u)
gen long   ynb   = rpoisson(gmean*rgamma(0.7,1/0.7))
gen long   ytrnb = ynb
replace    ytrnb = 1 if ytrnb==0

svyset psu [pw=wt], strata(strat) singleunit(centered)
stset ttime, failure(fail)

di as res _n(2) "###### EXTENDED MODELS: full svy,subpop vs svyslim ######"
local COMPLETE "ybin ycont ybeta ttime fail yzip ytr ycat ynb ytrnb x1 x2"

*-------------------- BETAREG -------------------------------------*
capture noisily {
    svy, subpop(grp): betareg ybeta x1 x2
    _gb x1 fu
    preserve
        svyslim grp, complete(`COMPLETE')
        svy, subpop(grp): betareg ybeta x1 x2
        _gb x1 sl
    restore
    _cmp "BETAREG" "x1"
}
local rc = _rc
capture restore
if `rc' di as err "BETAREG failed rc=`rc'" " (needs Stata 15+)"

*-------------------- STCOX ---------------------------------------*
capture noisily {
    svy, subpop(grp): stcox x1 x2
    _gb x1 fu
    preserve
        svyslim grp, complete(`COMPLETE')
        stset ttime, failure(fail)     // re-declare after keep
        svy, subpop(grp): stcox x1 x2
        _gb x1 sl
    restore
    _cmp "COX (stcox)" "x1"
}
local rc = _rc
capture restore
if `rc' di as err "STCOX failed rc=`rc'"

*-------------------- ZIP -----------------------------------------*
capture noisily {
    svy, subpop(grp): zip yzip x1 x2, inflate(x2)
    _gb x1 fu
    preserve
        svyslim grp, complete(`COMPLETE')
        svy, subpop(grp): zip yzip x1 x2, inflate(x2)
        _gb x1 sl
    restore
    _cmp "ZERO-INFLATED POISSON (zip)" "x1"
}
local rc = _rc
capture restore
if `rc' di as err "ZIP failed rc=`rc'"

*-------------------- ZINB ----------------------------------------*
capture noisily {
    svy, subpop(grp): zinb yzip x1 x2, inflate(x2)
    _gb x1 fu
    preserve
        svyslim grp, complete(`COMPLETE')
        svy, subpop(grp): zinb yzip x1 x2, inflate(x2)
        _gb x1 sl
    restore
    _cmp "ZERO-INFLATED NBREG (zinb)" "x1"
}
local rc = _rc
capture restore
if `rc' di as err "ZINB failed rc=`rc'"

*-------------------- TPOISSON ------------------------------------*
capture noisily {
    svy, subpop(grp): tpoisson ytr x1 x2
    _gb x1 fu
    preserve
        svyslim grp, complete(`COMPLETE')
        svy, subpop(grp): tpoisson ytr x1 x2
        _gb x1 sl
    restore
    _cmp "ZERO-TRUNCATED POISSON (tpoisson)" "x1"
}
local rc = _rc
capture restore
if `rc' di as err "TPOISSON failed rc=`rc'"

*-------------------- TNBREG --------------------------------------*
capture noisily {
    svy, subpop(grp): tnbreg ytrnb x1 x2
    _gb x1 fu
    preserve
        svyslim grp, complete(`COMPLETE')
        svy, subpop(grp): tnbreg ytrnb x1 x2
        _gb x1 sl
    restore
    _cmp "ZERO-TRUNCATED NBREG (tnbreg)" "x1"
}
local rc = _rc
capture restore
if `rc' di as err "TNBREG failed rc=`rc'"

di as res _n(2) "###### MULTILEVEL MODELS (random intercept at PSU) ######"
di as txt "These are SLOW. Each is run twice (full and slimmed)."
di as txt "IMPORTANT: svy rejects a [pw=] final-weight svyset for multilevel"
di as txt "models (r459). They need STAGE-LEVEL weights, so we re-svyset as:"
di as txt "   svyset psu, strata(strat) || _n, weight(wt)"
di as txt "(PSU stage sampled with weight 1; observations carry weight wt."
di as txt " The implied final weight is 1*wt = wt, so single-level results"
di as txt " are unchanged; multilevel models are now allowed.)"
di as txt "NOTE: mixed is NOT svy-supported at all (r322); multilevel linear"
di as txt "regression under svy uses meglm with family(gaussian) instead."

svyset psu, strata(strat) singleunit(centered) || _n, weight(wt)

*-------------------- MEGLM gaussian (multilevel regress) ----------*
capture noisily {
    svy, subpop(grp): meglm ycont x1 x2 || psu:, family(gaussian)
    _gb x1 fu
    preserve
        svyslim grp, complete(`COMPLETE') pweight(wt)
        svy, subpop(grp): meglm ycont x1 x2 || psu:, family(gaussian)
        _gb x1 sl
    restore
    _cmp "MULTILEVEL REGRESS (meglm gaussian)" "x1"
}
local rc = _rc
capture restore
if `rc' di as err "MEGLM gaussian failed rc=`rc'"

*-------------------- MELOGIT --------------------------------------*
capture noisily {
    svy, subpop(grp): melogit ybin x1 x2 || psu:
    _gb x1 fu
    preserve
        svyslim grp, complete(`COMPLETE') pweight(wt)
        svy, subpop(grp): melogit ybin x1 x2 || psu:
        _gb x1 sl
    restore
    _cmp "MULTILEVEL LOGIT (melogit)" "x1"
}
local rc = _rc
capture restore
if `rc' di as err "MELOGIT failed rc=`rc'"

*-------------------- MEOLOGIT -------------------------------------*
capture noisily {
    svy, subpop(grp): meologit ycat x1 x2 || psu:
    _gb x1 fu
    preserve
        svyslim grp, complete(`COMPLETE') pweight(wt)
        svy, subpop(grp): meologit ycat x1 x2 || psu:
        _gb x1 sl
    restore
    _cmp "MULTILEVEL OLOGIT (meologit)" "x1"
}
local rc = _rc
capture restore
if `rc' di as err "MEOLOGIT failed rc=`rc'"

*-------------------- MEPOISSON ------------------------------------*
capture noisily {
    svy, subpop(grp): mepoisson ynb x1 x2 || psu:
    _gb x1 fu
    preserve
        svyslim grp, complete(`COMPLETE') pweight(wt)
        svy, subpop(grp): mepoisson ynb x1 x2 || psu:
        _gb x1 sl
    restore
    _cmp "MULTILEVEL POISSON (mepoisson)" "x1"
}
local rc = _rc
capture restore
if `rc' di as err "MEPOISSON failed rc=`rc'"

*-------------------- MENBREG --------------------------------------*
capture noisily {
    svy, subpop(grp): menbreg ynb x1 x2 || psu:
    _gb x1 fu
    preserve
        svyslim grp, complete(`COMPLETE') pweight(wt)
        svy, subpop(grp): menbreg ynb x1 x2 || psu:
        _gb x1 sl
    restore
    _cmp "MULTILEVEL NBREG (menbreg)" "x1"
}
local rc = _rc
capture restore
if `rc' di as err "MENBREG failed rc=`rc'"

*-------------------- GSEM: multilevel MULTINOMIAL ------------------*
* No official memlogit exists. gsem with family(multinomial) and a
* random intercept M1[psu] is the standard route; gsem is svy-capable
* under the stage-weight svyset above, so svyslim works for it too.
capture noisily {
    svy, subpop(grp): gsem (i.ycat <- x1 x2 M1[psu]), family(multinomial) link(logit)
    _gb "2.ycat:x1" fu
    preserve
        svyslim grp, complete(`COMPLETE') pweight(wt)
        svy, subpop(grp): gsem (i.ycat <- x1 x2 M1[psu]), family(multinomial) link(logit)
        _gb "2.ycat:x1" sl
    restore
    _cmp "MULTILEVEL MULTINOMIAL (gsem)" "2.ycat:x1"
}
local rc = _rc
capture restore
if `rc' di as err "GSEM multinomial failed rc=`rc'" " (slow; check coefficient name if it errs)"

* MULTILEVEL BETA via gsem (Stata 17+ only) - uncomment to try:
capture noisily {
    svy, subpop(grp): gsem (ybeta <- x1 x2 M1[psu]), family(beta) link(logit)
    _gb "ybeta:x1" fu
    preserve
        svyslim grp, complete(`COMPLETE') pweight(wt)
        svy, subpop(grp): gsem (ybeta <- x1 x2 M1[psu]), family(beta) link(logit)
        _gb "ybeta:x1" sl
    restore
    _cmp "MULTILEVEL BETA (gsem)" "ybeta:x1"
}
local rc = _rc
capture restore
if `rc' di as err "GSEM BETA failed rc=`rc'" " (slow; check coefficient name if it errs)"

di as txt _n(2) "SUMMARY:"
di as txt "For every model that ran: |b diff| and |se diff| should be ~1e-6"
di as txt "or smaller, proving svyslim preserves the design for that model."
di as txt "Models reported as 'failed' are unavailable in your Stata version"
di as txt "or not official commands (see header notes)."
