*! svyslim v1.3  Reduce svyset data to a subpopulation while PRESERVING the
*! full survey design skeleton (every PSU and stratum), so that running
*!       svy, subpop(var): <model>
*! on the slimmed data reproduces the full-data  svy, subpop()  result
*! (coefficients AND standard errors) essentially exactly, while keeping
*! only the subpop rows plus one marker row per otherwise-empty PSU.
*!
*! Syntax:  svyslim subpopvar [, complete(varlist) totals
*!            impute(donor|all) psu() strata() pweight()]
*! The approach implements and automates a procedure sketched by Austin
*! Nichols on Statalist (24 Nov 2007), who suggested a -svysubset- package;
*! the totals option reproduces his summed-weight variant, which also
*! preserves the estimated population size e(N_pop).
*! Author: David Aduragbemi Okunlola (okunloladavid4@gmail.com; dao22@fsu.edu)
*!   complete(varlist): the covariates you will model; svyslim then chooses
*!                      marker rows that are non-missing on them, so the
*!                      empty PSUs are not dropped by casewise deletion.

program define svyslim, rclass
    version 14.0
    syntax varname(numeric) [, COMPlete(varlist numeric) TOTals IMPute(string) ///
        PSU(varname numeric) STRata(varname numeric) PWeight(varname numeric) ]
    local sp `varlist'

    * ---- read the design from svyset (unless overridden) ----------------
    quietly svyset
    local wt "`r(wvar)'"
    if "`pweight'" != "" local wt "`pweight'"
    if "`psu'"==""    local psu    "`r(su1)'"
    if "`strata'"=="" local strata "`r(strata1)'"
    if "`wt'"=="" {
        display as error "svyslim: no weight variable found. Either svyset"
        display as error "your data with [pw=wtvar], or pass pweight(wtvar)."
        display as error "(Stage-weight svyset designs for multilevel models"
        display as error "leave the final weight unset; pass pweight() there.)"
        exit 119
    }
    if "`psu'"=="" {
        display as error "svyslim: no PSU in svyset (or psu()); there is no"
        display as error "         design skeleton to preserve. Nothing to do."
        exit 459
    }
    if "`impute'" != "" & !inlist("`impute'","donor","all") {
        display as error "svyslim: impute() must be impute(donor) or impute(all)."
        display as error "  donor: fill marker blanks from rows of the SAME"
        display as error "         cluster only; cluster-wide-missing variables"
        display as error "         stay missing (slim then matches full-data svy)."
        display as error "  all  : donor first, then the variable's observed"
        display as error "         minimum anywhere in the data, so markers are"
        display as error "         always complete and empty PSUs always retained."
        exit 198
    }

    * ---- 1) does each PSU contain at least one subpop member? -----------
    tempvar haspop ok marker notok
    quietly bysort `psu': egen byte `haspop' = max(`sp'!=0 & `sp'<.)

    * ---- 2) a row is usable as a marker if its design + (optional) model
    *         variables are non-missing, so svy will not drop it ----------
    quietly gen byte `ok' = !missing(`wt')
    quietly replace `ok' = 0 if missing(`psu')
    if "`strata'"!="" quietly replace `ok' = 0 if missing(`strata')
    if "`complete'"!="" {
        foreach v of varlist `complete' {
            quietly replace `ok' = 0 if missing(`v')
        }
    }

    * ---- 3) choose the marker rows ---------------------------------------
    quietly gen byte `notok' = !`ok'
    if "`totals'" == "" {
        * MINIMAL mode: one marker per EMPTY PSU (prefer a usable row;
        * fall back to the first row otherwise). Coefficients and SEs
        * match svy, subpop() exactly; e(N_pop) is not preserved.
        quietly bysort `psu' (`notok'): gen byte `marker' = (`haspop'==0 & _n==1)
    }
    else {
        * TOTALS mode (Nichols 2007): one marker per PSU that has ANY
        * usable excluded row, carrying the SUM of the excluded rows'
        * weights. Coefficients and SEs match exactly, AND the estimated
        * population size e(N_pop) matches the full-data run.
        tempvar excl gid sumw pick
        quietly gen byte `excl' = `ok' & !(`sp'!=0 & `sp'<.)
        if "`strata'"!="" quietly egen long `gid' = group(`strata' `psu')
        else              quietly egen long `gid' = group(`psu')
        quietly bysort `gid': egen double `sumw' = total(cond(`excl'==1, `wt', 0))
        if "`impute'" == "" {
            quietly gen byte `pick' = !`excl'
            quietly bysort `gid' (`pick'): gen byte `marker' = (`excl'==1 & _n==1)
        }
        else {
            * with impute, any excluded row may serve; prefer fully-ok ones
            tempvar anyx pick2
            quietly gen byte `anyx'  = !(`sp'!=0 & `sp'<.)
            quietly gen byte `pick2' = cond(`excl'==1, 0, cond(`anyx'==1, 1, 2))
            quietly bysort `gid' (`pick2'): gen byte `marker' = (`anyx'==1 & _n==1)
        }
        quietly recast double `wt'
        quietly replace `wt' = `sumw' if `marker'==1 & `sumw' > 0
    }

    * ---- 3b) impute option: repair bad markers by within-cluster donation
    *  A marker's values NEVER enter estimation (its subpop multiplier is 0);
    *  they only decide whether svy keeps the row. So missing complete()
    *  variables on a marker are filled with a randomly drawn OBSERVED value
    *  from a non-subpop row in the SAME cluster. If no row in the cluster
    *  has the variable observed, it stays missing - and svy then drops the
    *  marker for models using it, exactly as the full data would drop that
    *  cluster, so results remain consistent.
    if "`impute'" != "" {
        if "`complete'" == "" {
            display as error "svyslim: impute() requires complete()"
            display as error "(it fills exactly those variables)."
            exit 198
        }
        tempvar uu
        quietly gen double `uu' = runiform()
        foreach v of varlist `complete' {
            tempvar hasv negh dv
            quietly gen byte `hasv' = !missing(`v') & !(`sp'!=0 & `sp'<.)
            quietly gen byte `negh' = !`hasv'
            quietly bysort `psu' (`negh' `uu'): ///
                gen double `dv' = cond(`negh'[1]==0, `v'[1], .)
            quietly replace `v' = `dv' if `marker'==1 & missing(`v')
            quietly drop `hasv' `negh' `dv'
            if "`impute'" == "all" {
                * dataset-wide fallback: the variable's observed MINIMUM is a
                * real, type-valid code from your own data (e.g. the lowest
                * marital-status code); the value is never used in estimation.
                quietly summarize `v', meanonly
                if r(N) > 0 {
                    quietly replace `v' = r(min) if `marker'==1 & missing(`v')
                }
            }
        }
        * markers may now be complete: refresh their usability flag
        quietly replace `ok' = !missing(`wt') if `marker'==1
        quietly replace `ok' = 0 if `marker'==1 & missing(`psu')
        if "`strata'"!="" ///
            quietly replace `ok' = 0 if `marker'==1 & missing(`strata')
        foreach v of varlist `complete' {
            quietly replace `ok' = 0 if `marker'==1 & missing(`v')
        }
    }

    * ---- counts for the report -----------------------------------------
    quietly count
    local n0 = r(N)
    quietly count if (`sp'!=0 & `sp'<.)
    local nsp = r(N)
    quietly count if `marker'==1
    local nmk = r(N)
    quietly count if `marker'==1 & `ok'==0
    local nbad = r(N)

    * ---- 4) keep subpop members + markers ------------------------------
    quietly keep if (`sp'!=0 & `sp'<.) | `marker'==1
    quietly count
    local n1 = r(N)

    display as text "------------------------------------------------------------"
    display as text "svyslim: design-preserving reduction to subpop = `sp'"
    if "`totals'"=="" ///
        display as text "  mode: minimal markers (e(N_pop) not preserved)"
    else ///
        display as text "  mode: totals (Nichols 2007; e(N_pop) preserved)"
    display as text "  full rows               = " as result %12.0fc `n0'
    display as text "  subpop rows kept         = " as result %12.0fc `nsp'
    display as text "  empty-PSU marker rows    = " as result %12.0fc `nmk'
    display as text "  rows now in memory       = " as result %12.0fc `n1'
    display as text "------------------------------------------------------------"
    display as text "ANALYZE WITH:  svy, subpop(`sp'): <model>   (NOT plain svy:)"
    display as text "  -> matches the full-data  svy, subpop(`sp')  result."
    if `nbad' > 0 {
        if "`impute'" == "" {
            display as error "  WARNING: `nbad' marker(s) have a missing"
            display as error "  complete() variable; svy will drop them, and"
            display as error "  their clusters, by casewise deletion. Fix:"
            display as error "  widen complete(), or add impute() to fill"
            display as error "  markers with donated values from their own"
            display as error "  cluster (never used in estimation, because"
            display as error "  markers are outside the subpopulation)."
        }
        else if "`impute'" == "donor" {
            display as text "  NOTE: `nbad' marker(s) still miss a complete()"
            display as text "  variable because NO row in their cluster"
            display as text "  observes it. svy drops them for models using"
            display as text "  that variable - exactly as the full data drops"
            display as text "  those clusters - so results stay consistent."
        }
        else {
            display as text "  NOTE: `nbad' marker(s) remain incomplete:"
            display as text "  a complete() variable is observed NOWHERE in"
            display as text "  the data; models using it have no sample anyway."
        }
    }

    return scalar N_full    = `n0'
    return scalar N_subpop  = `nsp'
    return scalar N_marker  = `nmk'
    return scalar N_kept    = `n1'
    if "`impute'"=="" return local impute "off"
    else return local impute "`impute'"
    if "`totals'"=="" return local mode "minimal"
    else return local mode "totals"
end
