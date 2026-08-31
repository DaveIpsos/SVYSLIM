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
gen byte mysubpop = (age >= 65)         // you define the subpopulation
svyslim mysubpop, complete(y x1 x2)     // subpop rows + markers
save subpop_slim, replace

* FROM NOW ON: fast, on the small file
use subpop_slim, clear
svy, subpop(mysubpop): logit y x1 x2    // == full-data svy, subpop()
* multilevel models need a stage-weight svyset first:
svyset psu, strata(strat) || _n, weight(wt)
svy, subpop(mysubpop): melogit y x1 x2 || psu:
```

### One-line form

For a single model, the prefix form does the whole two-step in one
command — it preserves your data, reduces it, runs `svy, subpop()`, and
restores the full data:

```stata
gen byte mysubpop = (age >= 65)
svyslim mysubpop, complete(y x1 x2): logit y x1 x2
```

Omit `complete()` and `svyslim` infers the model's variables, so the
shortest form is `svyslim mysubpop: logit y x1 x2`. (For `if`/`in`,
time-series operators, or unusual syntax, give `complete()` explicitly;
for multilevel models, pass `pweight(wt)`.) The two-step form is still
preferred when fitting **many** models — reduce and save once, then
analyze repeatedly — and for postestimation (`margins`, `predict`),
which needs the reduced sample in memory.

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
| `svyslim_dhs_test.do` | proof on the free DHS model dataset |
| `svyslim_oneline_test.do` | proof the one-line form matches the two-step |
| `svyslim_scaling_benchmark.do` | speed benchmark vs svy, subpop() at 2-6M rows |
| `svyslim_scaling_benchmark.do` | speed benchmark vs `svy, subpop()` at 2–6M rows |
| `Complex_Survey_and_svyslim_Guide.pdf` | beginner-friendly study guide (PDF) |
| `Complex_Survey_and_svyslim_Guide.docx` | the same guide, editable Word version |


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
and a complex multilevel model (`melogit`). Route **A** is full-data
`svy, subpop()`; route **B** is `svyslim` + `svy, subpop()` on the
reduced file (its time includes the one-time reduction). All 18 cells:

| Model | Subpop | Total N | Subpop N | A: full (s) | B: svyslim (s) | Saved (s) | % faster | Speedup | se diff |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| logit | 50% | 2M | 1,000,000 | 7.7 | 2.8 | 4.9 | 64% | 2.78× | 4.3e-19 |
| logit | 50% | 4M | 2,000,000 | 14.2 | 6.7 | 7.6 | 53% | 2.13× | 4.3e-19 |
| logit | 50% | 6M | 3,000,000 | 19.7 | 9.4 | 10.3 | 52% | 2.10× | 2.2e-19 |
| logit | 20% | 2M | 400,000 | 5.1 | 1.7 | 3.5 | 68% | 3.11× | 1.7e-18 |
| logit | 20% | 4M | 800,000 | 11.3 | 3.2 | 8.1 | 72% | 3.57× | 4.3e-19 |
| logit | 20% | 6M | 1,200,000 | 16.3 | 4.4 | 11.9 | 73% | 3.72× | 0.0e+00 |
| logit | 5% | 2M | 100,000 | 5.5 | 1.3 | 4.2 | 77% | 4.33× | 0.0e+00 |
| logit | 5% | 4M | 200,000 | 10.7 | 1.9 | 8.8 | 82% | 5.62× | 1.7e-18 |
| logit | 5% | 6M | 300,000 | 18.8 | 2.5 | 16.3 | 87% | **7.47×** | 0.0e+00 |
| melogit | 50% | 2M | 1,000,000 | 36.6 | 24.8 | 11.8 | 32% | 1.47× | 4.3e-19 |
| melogit | 50% | 4M | 2,000,000 | 128.9 | 82.1 | 46.8 | 36% | 1.57× | 0.0e+00 |
| melogit | 50% | 6M | 3,000,000 | 126.1 | 80.3 | 45.8 | 36% | 1.57× | 0.0e+00 |
| melogit | 20% | 2M | 400,000 | 23.2 | 10.2 | 12.9 | 56% | 2.27× | 0.0e+00 |
| melogit | 20% | 4M | 800,000 | 52.1 | 22.2 | 29.9 | 57% | 2.34× | 0.0e+00 |
| melogit | 20% | 6M | 1,200,000 | 72.4 | 29.2 | 43.2 | 60% | 2.48× | 0.0e+00 |
| melogit | 5% | 2M | 100,000 | 18.6 | 3.5 | 15.1 | 81% | 5.28× | 1.7e-18 |
| melogit | 5% | 4M | 200,000 | 39.7 | 6.1 | 33.6 | 85% | 6.54× | 0.0e+00 |
| melogit | 5% | 6M | 300,000 | 54.9 | 7.9 | 47.0 | 86% | **6.95×** | 0.0e+00 |

Two results hold across all 18 cells (three sizes × three subpop shares
× two models): (1) **exact agreement** — the largest difference in the
x1 standard error (`se diff`) between full-data and slimmed runs was
1.7 × 10⁻¹⁸ (machine precision), so exactness does not degrade as data
grow; and (2) `svyslim` was **faster in every cell** — 1.47× to 7.47×.
The speedup grows monotonically as the subpopulation shrinks, because
that is what `svyslim` deletes, so the largest gains (up to ~7.5×) come
in `svyslim`'s intended regime: a small subpopulation of a large file.
Even at a 50% subpopulation it was 1.5–2.8× faster and never slower. As a concrete illustration, in the small-subpopulation regime a multilevel model that takes about **7 minutes** on the full data finishes in about **1 minute** on the reduced data (≈ 7×, matching the measured ratios).
Reproduce with `svyslim_scaling_benchmark.do`. (`A` = full-data
`svy, subpop()`; `B` = `svyslim` + `svy, subpop()`, including the
one-time reduction; Saved = A − B; % faster = 100 × (A − B)/A;
Speedup = A/B. Absolute times depend on hardware and Stata flavor; the
ratios are the point.)

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
