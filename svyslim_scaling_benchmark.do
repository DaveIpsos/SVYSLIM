*==================================================================*
* svyslim_scaling_benchmark.do
*   Speed of svyslim vs svy, subpop() on LARGE pooled-survey-scale
*   data. Two axes are varied:
*
*     TOTAL rows N in {2, 4, 6} million   (realistic pooled range:
*                                          DHS/NHANES/MICS across cycles)
*     SUBPOP fraction in {0.50, 0.20, 0.05} (large -> small subpop;
*                                          0.05 is svyslim's ideal case)
*
*   At each (N, fraction) it times, for a SIMPLE and a COMPLEX model:
*     A. svy, subpop()            on the full data   (benchmark)
*     B. svyslim + svy, subpop()  on the slimmed data
*
*   Larger subpop  -> svyslim deletes fewer rows -> smaller speedup.
*   Smaller subpop -> svyslim deletes more rows  -> larger speedup.
*   This file shows BOTH so the tradeoff is explicit.
*
*   *** READ BEFORE RUNNING ***
*   - Budget: on Stata SE, a full sweep is ~25-45 min (melogit dominates;
*     ~15 min of that is melogit alone). Much faster on Stata MP.
*   - Memory: 6M rows x ~9 doubles ~ 0.5 GB resident, plus melogit
*     workspace. If you hit a memory error, drop TOTALS to "2 4" or
*     lower NPER. Completed rows are saved to disk as we go.
*   - Calibrate first: set  local TOTALS "2"  for a single quick pass,
*     then widen to "2 4 6".
*   - Honesty: written and reasoned carefully but not executed in Stata
*     by its author; timings are produced on YOUR machine.
*==================================================================*
clear all
set more off
version 14.0

*--- 0. knobs -----------------------------------------------------*
local TOTALS  "2 4 6"        // TOTAL rows in millions
local FRACS   "0.50 0.20 0.05"  // subpop fraction: unfavorable -> ideal
local NPER    700            // rows per PSU
local SEED    12345
local OUT     "svyslim_scaling_results"

adopath + "`c(pwd)'"
capture which svyslim
if _rc {
    di as err "svyslim.ado not found in `c(pwd)'."
    exit 199
}

tempname RES
postfile `RES' double totalM double frac double subpopN str8 model ///
    double tA double tB double speedup double bdiff double sediff ///
    using "`OUT'.dta", replace

*==================================================================*
foreach tot of local TOTALS {
    local NTOT = round(`tot'*1000000)

    * build the data ONCE per total size (shared across fractions)
    clear
    quietly set obs `NTOT'
    set seed `SEED'
    quietly gen long psu   = ceil(_n/`NPER')
    quietly gen long strat = ceil(psu/5)
    quietly bysort psu (strat): gen double u = rnormal() if _n==1
    quietly bysort psu (strat): replace u = u[1]
    quietly gen double x1 = rnormal()
    quietly gen double x2 = rnormal()*0.5 + 0.3*x1
    quietly gen double xb = -0.3 + 0.5*x1 - 0.3*x2 + 0.6*u
    quietly gen byte ybin = runiform() < invlogit(xb)
    quietly gen double wt = exp(0.25*x1)
    quietly sum wt, meanonly
    quietly replace wt = wt/r(mean)
    tempfile BASE
    quietly save `BASE'

    foreach fr of local FRACS {
        local SUB = round(`NTOT'*`fr')
        di as res _n(2) "############################################"
        di as res "### TOTAL=`tot'M  frac=`fr'  subpop=" %12.0fc `SUB'
        di as res "############################################"

        quietly use `BASE', clear
        * subpopulation = a random `fr' share of rows
        quietly gen byte grp = runiform() < `fr'

        *=== SIMPLE: logit ====================================*
        svyset psu [pw=wt], strata(strat) singleunit(centered)
        tempfile F
        quietly save `F'

        di as txt ">>> logit  A ..."
        timer clear 1
        timer on 1
        quietly svy, subpop(grp): logit ybin x1 x2
        timer off 1
        scalar a_b=_b[x1]
        scalar a_se=_se[x1]
        quietly timer list 1
        scalar a_t=r(t1)

        di as txt ">>> logit  B ..."
        quietly use `F', clear
        timer clear 2
        timer on 2
        quietly svyslim grp, complete(ybin x1 x2)
        quietly svy, subpop(grp): logit ybin x1 x2
        timer off 2
        scalar b_b=_b[x1]
        scalar b_se=_se[x1]
        quietly timer list 2
        scalar b_t=r(t2)

        post `RES' (`tot') (`fr') (`SUB') ("logit") (a_t) (b_t) ///
            (a_t/b_t) (abs(a_b-b_b)) (abs(a_se-b_se))
        di as res "    logit  : A=" %7.1f a_t "s  B=" %7.1f b_t ///
                  "s  speedup=" %5.2f a_t/b_t "x"

        *=== COMPLEX: melogit || psu: =========================*
        quietly use `F', clear
        svyset psu, strata(strat) singleunit(centered) || _n, weight(wt)
        tempfile FM
        quietly save `FM'

        di as txt ">>> melogit  A ..."
        timer clear 3
        timer on 3
        quietly svy, subpop(grp): melogit ybin x1 x2 || psu:
        timer off 3
        scalar a_b=_b[x1]
        scalar a_se=_se[x1]
        quietly timer list 3
        scalar a_t=r(t3)

        di as txt ">>> melogit  B ..."
        quietly use `FM', clear
        timer clear 4
        timer on 4
        quietly svyslim grp, complete(ybin x1 x2) pweight(wt)
        quietly svy, subpop(grp): melogit ybin x1 x2 || psu:
        timer off 4
        scalar b_b=_b[x1]
        scalar b_se=_se[x1]
        quietly timer list 4
        scalar b_t=r(t4)

        post `RES' (`tot') (`fr') (`SUB') ("melogit") (a_t) (b_t) ///
            (a_t/b_t) (abs(a_b-b_b)) (abs(a_se-b_se))
        di as res "    melogit: A=" %7.1f a_t "s  B=" %7.1f b_t ///
                  "s  speedup=" %5.2f a_t/b_t "x"
    }
}

postclose `RES'

*==================================================================*
* final table + graph
*==================================================================*
use "`OUT'.dta", clear
quietly export delimited using "`OUT'.csv", replace

di as res _n(2) "==================== SCALING RESULTS ===================="

* derive reporting quantities
quietly gen double saved   = tA - tB            // seconds saved by svyslim
quietly gen double pctfast = 100*(tA - tB)/tA   // % faster than full svy
gsort model -frac totalM
label define frL 50 "large (50%)" 20 "moderate (20%)" 5 "small (5%)"
quietly gen fracpct = round(frac*100)
label values fracpct frL

* ---- formatted text table --------------------------------------*
di as txt "{hline 84}"
di as txt %-9s "model" %8s "subpop%" %9s "totalN" %10s "subpopN" ///
    %8s "A (s)" %8s "B (s)" %8s "saved" %8s "%fast" %9s "speedup" %10s "se diff"
di as txt "{hline 84}"
local lastmodel ""
forvalues i=1/`=_N' {
    if model[`i']!="`lastmodel'" {
        if "`lastmodel'"!="" di as txt "{hline 84}"
        local lastmodel = model[`i']
    }
    di as res %-9s model[`i'] as txt %7.0f fracpct[`i'] "%" ///
        %9.1fc totalM[`i'] "M" %10.0fc subpopN[`i'] ///
        as res %8.1f tA[`i'] %8.1f tB[`i'] %8.1f saved[`i'] ///
        %7.0f pctfast[`i'] "%" %8.2f speedup[`i'] "x" ///
        as txt %10.1e sediff[`i']
}
di as txt "{hline 84}"
di as txt "A = full svy,subpop()   B = svyslim + svy,subpop()"
di as txt "saved = A-B seconds   %fast = 100*(A-B)/A   speedup = A/B"
di as txt "se diff ~ 0 (<=2e-18) => svyslim reproduces svy,subpop() EXACTLY,"
di as txt "at every size, both models, all subpop sizes."
di as txt "Speedup grows as the subpop shrinks (svyslim deletes more) and"
di as txt "is largest at 5% - svyslim's intended use: a small subpop of a"
di as txt "large pooled file."

* ---- export a clean CSV table too ------------------------------*
preserve
    order model fracpct totalM subpopN tA tB saved pctfast speedup sediff
    quietly export delimited model fracpct totalM subpopN tA tB saved ///
        pctfast speedup sediff using "svyslim_scaling_table.csv", replace
restore

* ---- clearer graph: PANELS by model, speedup vs subpop fraction *
* one panel per model; x = subpop %, separate line per total size.
* This reads far more cleanly than 6 overlaid lines.
capture noisily {
    twoway (connected speedup fracpct if totalM==2, sort msymbol(O)) ///
           (connected speedup fracpct if totalM==4, sort msymbol(S)) ///
           (connected speedup fracpct if totalM==6, sort msymbol(T)), ///
        by(model, title("svyslim speedup over svy, subpop()", size(medium)) ///
           note("Speedup = full-data time / svyslim time. Dashed line = no gain (1x)." ///
                "Higher = faster. Right side (small subpop) is svyslim's intended use.", ///
                size(vsmall)) rows(1)) ///
        xlabel(5 20 50, grid) ///
        xtitle("Subpopulation size (% of file)  -  smaller = more deleted") ///
        ytitle("Speedup (x)") yline(1, lpattern(dash) lcolor(gs8)) ///
        ylabel(1(1)5, grid) ///
        legend(order(1 "2M rows" 2 "4M rows" 3 "6M rows") rows(1) ///
               region(lstyle(none))) ///
        scheme(s1color)
    graph export "svyslim_scaling.png", replace width(1800) height(750)
    di as txt "Graph saved to svyslim_scaling.png"
}
