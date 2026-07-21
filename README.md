# svyslim

A Stata command for fast, design-correct analysis of subpopulations in
large complex survey datasets (DHS, MICS, NHANES, NSFG, PISA, and
similar).

**Author:** David Aduragbemi Okunlola
(okunloladavid4@gmail.com; dao22@fsu.edu)
Department of Sociology, Florida State University, Tallahassee, FL, USA.

---

## The problem

You have millions of survey rows but only care about ~5,000 respondents
(e.g., currently pregnant women). Keeping the full file in memory makes
every model crawl — but the standard advice says you *cannot* delete the
other rows: `keep if subpop` silently deletes every PSU (cluster) that
contains no subpopulation members, which changes the design degrees of
freedom and the per-stratum cluster counts, so standard errors no longer
match the correct `svy, subpop()` result.

## The fix: svyslim

`svyslim` shrinks the data while preserving the full survey design
skeleton. It keeps all subpopulation rows **plus one "marker" row from
each PSU that would otherwise vanish**. Markers are outside the
subpopulation, so they contribute zero to estimation — but they keep
their PSUs alive and counted, exactly as `svy, subpop()` treats empty
PSUs. Result: `svy, subpop()` on the small file reproduces the full-data
result — coefficients, standard errors, and design df — verified to
machine precision in simulation.

Because `svyslim` only slims the *data* and never touches the model, it
works with **any** command that runs under `svy:` — regress, logit,
probit, mlogit, ologit, poisson, nbreg, betareg, stcox, zip, zinb,
tpoisson, tnbreg, mean, the multilevel commands (meglm, melogit,
meologit, mepoisson, menbreg), and gsem. (Multilevel note: `mixed` is
not svy-supported — use `meglm, family(gaussian)` — and multilevel
models need a stage-weight svyset: `svyset psu, strata(s) || _n,
weight(wt)`, with `pweight(wt)` passed to svyslim.)

```stata
* ONE TIME: shrink the big file
use bigdata, clear
svyset psu [pw=wt], strata(strat)
svyslim mysubpop, complete(y x1 x2)     // subpop rows + markers
save subpop_slim, replace

* FROM NOW ON: fast, on the small file
use subpop_slim, clear
svy, subpop(mysubpop): logit y x1 x2    // == full-data svy, subpop()
* multilevel models need a stage-weight svyset first:
svyset psu, strata(strat) || _n, weight(wt)
svy, subpop(mysubpop): melogit y x1 x2 || psu:
```

### Syntax

```
svyslim subpopvar [, complete(varlist) totals impute(donor|all)
        psu(varname) strata(varname) pweight(varname)]
```

**Two modes.** By default, coefficients, standard errors, and design df
match the full data exactly; the estimated population size `e(N_pop)`
does not (harmless for inference). Add the `totals` option — the
Nichols (2007) variant — and markers carry the summed weights of the
dropped rows in their PSU, so `e(N_pop)` is preserved too.

**The `impute()` option.** When an empty cluster has no fully observed
row, its fallback marker would be dropped by casewise deletion. Filled
marker values never enter estimation (the subpop multiplier is zero),
so repair is safe, and **only marker rows are ever filled —
subpopulation rows are never touched**. `impute(donor)` fills blanks
from rows of the *same* cluster only; cluster-wide-missing variables
stay missing, matching how the full data drops that cluster.
`impute(all)` additionally falls back to the variable's observed
minimum anywhere in the data — always a real, type-valid code — so
markers are always complete and every empty cluster is always retained
(a deliberate design-based choice that can diverge slightly from the
full-data run wherever full data would drop a cluster entirely). Off by
default to preserve the exactness guarantee.

**Two golden rules.** (1) On the slimmed file, always use
`svy, subpop():`, never plain `svy:` — the markers must be excluded by
`subpop()`. (2) Pass `complete()` listing every variable your models
will use, so no marker is dropped for a missing value.

**Stored results.** `r(N_full)`, `r(N_subpop)`, `r(N_marker)`,
`r(N_kept)` (scalars); `r(mode)` (`minimal` or `totals`) and
`r(impute)` (`off`, `donor`, or `all`) (macros).

## Files

| File | What it is |
|---|---|
| `svyslim.ado` | the command (v1.3) |
| `svyslim.sthlp` | in-Stata help (`help svyslim`) |
| `svyslim_verify.do` | proof: basic models + `totals` + `impute()`, simulated survey |
| `svyslim_models_test.do` | proof: betareg / stcox / zip / zinb / tpoisson / tnbreg / multilevel / gsem |
| `svyslim_dhs_tests.do` | proof on the free DHS model dataset |
| `svyslim_scaling_benchmark.do` | speed benchmark vs `svy, subpop()` at 2–6M rows |
| `figure1_subpop.pdf`, `figure2_keepvsslim.pdf` | manuscript figures (grayscale, 300 dpi) |

The **PDF/Word manual** (`Complex_Survey_and_svyslim_Guide`) is a
from-scratch tutorial: it explains complex survey concepts (weights,
strata, PSUs, design df), shows with a hand-checkable worked example why
`keep` and `svy, subpop()` disagree, and walks through `svyslim.ado`
piece by piece — the code shown there is sliced directly from the ado,
so the walkthrough always matches the real file, including the `totals`
and `impute()` options.

## Install

Copy `svyslim.ado` and `svyslim.sthlp` into your PERSONAL ado folder
(type `sysdir` in Stata to find it; create it if it does not exist),
then run `discard`. Check with `which svyslim`.

## Verify before relying on it

Run any of the three test do-files. For every model, the reported
`|b diff|` and `|se diff|` between the full-data and slimmed runs should
be about 1e-6 or smaller. `svyslim_verify.do` also checks that `totals`
reproduces `e(N_pop)` and that `impute()` repairs bad markers.

## Speed on large data

Benchmarked against full-data `svy, subpop()` on simulated stratified
cluster samples at pooled-survey scale (2, 4, and 6 million rows), at
three subpopulation sizes (50%, 20%, 5%), for a simple model (`logit`)
and a complex multilevel model (`melogit`). Route B is `svyslim` +
`svy, subpop()` on the reduced file (its time includes the one-time
reduction). Selected rows at 6M:

| Model | Subpop | full (s) | svyslim (s) | speedup | sediff |
|---|---|---|---|---|---|
| logit | 50% | 19.7 | 9.4 | 2.10× | 2.2e-19 |
| logit | 20% | 16.3 | 4.4 | 3.72× | 0.0e+00 |
| logit | 5% | 18.8 | 2.5 | **7.47×** | 0.0e+00 |
| melogit | 50% | 126.1 | 80.3 | 1.57× | 0.0e+00 |
| melogit | 20% | 72.4 | 29.2 | 2.48× | 0.0e+00 |
| melogit | 5% | 54.9 | 7.9 | **6.95×** | 0.0e+00 |

Two results hold across all 18 cells (three sizes × three subpop shares
× two models): (1) **exact agreement** — the largest difference in the
x1 standard error (sediff) between full-data and slimmed runs was 1.7e-18
(machine precision), so exactness does not degrade as data grow; and
(2) `svyslim` was **faster in every cell** — 1.47× to 7.47×. The
speedup grows monotonically as the subpopulation shrinks, because that
is what `svyslim` deletes, so the largest gains (up to ~7.5×) come in
`svyslim`'s intended regime: a small subpopulation of a large file.
Even at a 50% subpopulation it was 1.5–2.8× faster and never slower.
Reproduce with `svyslim_scaling_benchmark.do`. (Absolute times depend
on hardware and Stata flavor; the ratios are the point.)

## When it helps — and when it does not

`svyslim` shrinks data only when PSUs are real clusters holding many
people, so a scattered subpopulation leaves whole clusters empty. It
does **not** help when each individual is their own PSU (e.g., BRFSS as
usually svyset) — then nearly every excluded person would become a
marker. If the subpopulation appears in every PSU, plain `keep` already
matches `svy, subpop()` and `svyslim` simply adds zero markers.

## Status and caveats

Prototype (v1.3). The statistics are verified by simulation to machine
precision; validate on your own design with the test do-files. Default
mode does not preserve `e(N_pop)` (use `totals` if you need it).
Multi-stage designs are handled through first-stage PSUs (what
linearized survey variance uses); later-stage finite population
corrections are not adjusted. Requires Stata 14+; some tested models
need newer versions (betareg 15+, gsem family(beta) 17+). Multilevel
zero-inflated / zero-truncated models (mezip, mezinb, metpoisson,
metnbreg) do not exist as official Stata commands and are out of scope.

## Acknowledgment and provenance

The core idea — retain the excluded rows' design skeleton so that
`svy, subpop()` on a reduced dataset reproduces the full-data result —
was sketched by Austin Nichols on Statalist (24 Nov 2007;
https://www.stata.com/statalist/archive/2007-11/msg00810.html). He
suggested a `-svysubset-` package but was concerned that model-specific
missing-value patterns would defeat automation; no public implementation
appeared in the years since. `svyslim` implements and generalizes his
procedure: the `complete()` option answers the missing-value concern by
letting the user declare the union of model variables once, and the
`totals` option reproduces his summed-weight variant (preserving
`e(N_pop)`).

## License and citation

Free to use with attribution. If this saves you compute time in
published work, a citation or acknowledgment is appreciated:

> Okunlola, D. A. svyslim: Design-preserving subpopulation reduction for
> complex survey data in Stata.
