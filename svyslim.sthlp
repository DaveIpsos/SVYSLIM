{smcl}
{* svyslim help v1.3}{...}
{hi:help svyslim}{...}
{title:Title}

{p 4 8}{cmd:svyslim} {hline 2} Reduce svyset data to a subpopulation while
preserving the full survey design skeleton (every PSU and stratum), so that
{cmd:svy, subpop():} on the slimmed data reproduces the full-data
{cmd:svy, subpop()} result {hline 2} coefficients, standard errors, and design
degrees of freedom {hline 2} on a fraction of the rows.{p_end}

{title:Syntax}

{p 8 16}{cmd:svyslim} {it:subpopvar} [{cmd:,} {it:options}]{p_end}

{p 4 8}{it:subpopvar} is a numeric 0/1 indicator for your subpopulation
(nonzero and nonmissing = member). It is the same variable you will later pass
to {cmd:svy, subpop()}.{p_end}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt comp:lete(varlist)}}the variables you will model (outcome and
predictors); marker rows are chosen to be nonmissing on them{p_end}
{synopt:{opt psu(varname)}}PSU variable (default: read from {cmd:svyset}){p_end}
{synopt:{opt str:ata(varname)}}strata variable (default: read from {cmd:svyset}){p_end}
{synopt:{opt imp:ute(mode)}}repair markers that have missing {opt complete()} values;
{it:mode} is {cmd:donor} (fill from the same cluster only) or {cmd:all} (donor first,
then the variable's observed minimum anywhere in the data). Filled values never enter
estimation; see below{p_end}
{synopt:{opt tot:als}}Nichols (2007) variant: markers carry the summed weights of the
dropped rows in their PSU, so the estimated population size e(N_pop) is also preserved{p_end}
{synopt:{opt pw:eight(varname)}}final weight variable; required when the data are
svyset with stage-level weights (the multilevel setup), which leaves no final [pw=] weight{p_end}
{synoptline}

{p 4 8}The data must be {cmd:svyset} (with a PSU) before running {cmd:svyslim}.
{cmd:svyslim} changes the data in memory (it drops rows), so run it inside
{cmd:preserve}/{cmd:restore} or save the result to a new file.{p_end}

{title:Description}

{p 4 8}Deleting non-subpopulation rows with {cmd:keep} also deletes every PSU
that contains no subpopulation members. That changes the design degrees of
freedom (df = number of PSUs minus number of strata) and the per-stratum
cluster counts, so standard errors no longer match {cmd:svy, subpop()} on the
full data.{p_end}

{p 4 8}{cmd:svyslim} avoids this by keeping, in addition to all subpopulation
rows, {bf:one marker row from each PSU that would otherwise vanish}. A marker
is outside the subpopulation, so it contributes zero to estimation, but it
keeps its PSU alive and counted {hline 2} exactly how {cmd:svy, subpop()}
treats empty PSUs. The result: the slimmed file gives the same estimates, the
same standard errors, and the same design df as the full file, verified to
machine precision in simulation.{p_end}

{p 4 8}Because {cmd:svyslim} only slims the data and never touches the model,
it works with {bf:any} command that runs under {cmd:svy:}, including
{cmd:regress}, {cmd:logit}, {cmd:probit}, {cmd:mlogit}, {cmd:ologit},
{cmd:poisson}, {cmd:nbreg}, {cmd:betareg}, {cmd:stcox}, {cmd:zip}, {cmd:zinb},
{cmd:tpoisson}, {cmd:tnbreg}, {cmd:mean}, the multilevel commands
({cmd:mixed}, {cmd:melogit}, {cmd:meologit}, {cmd:mepoisson}, {cmd:menbreg},
...), and {cmd:gsem}.{p_end}

{title:Two modes}

{p 4 8}{bf:Default (minimal) mode} keeps one marker per otherwise-empty PSU with its
original weight. Coefficients, standard errors, and design df match the full-data
{cmd:svy, subpop()} exactly; the estimated population size {cmd:e(N_pop)} is smaller
than in the full data (the dropped rows' weights are gone), which does not affect
inference on model parameters.{p_end}

{p 4 8}{bf:totals mode} ({opt totals} option) additionally places one marker in every
PSU that had usable excluded rows, carrying the {it:sum} of those rows' weights (the
marker row's value on the weight variable is overwritten). This reproduces the variant
sketched by Nichols (2007) and preserves {cmd:e(N_pop)} as well, at the cost of one
extra row per PSU. Use it when you will report estimated population totals or want
every stored survey result to match.{p_end}

{title:The impute() option}

{p 4 8}A marker's values never enter estimation {hline 2} its {cmd:subpop()}
multiplier is zero {hline 2} so they matter only for whether {cmd:svy} keeps the row.
When an empty cluster has no fully observed row, the default fallback marker will be
dropped by casewise deletion and its cluster vanishes for models using the missing
variable. {opt impute(donor)} fills each missing {opt complete()} variable on a marker
with a randomly drawn {it:observed} value from a non-subpopulation row in the {it:same}
cluster; a variable no row in the cluster observes stays missing, so the marker is
dropped for models using it {hline 2} exactly as the full data would drop that whole
cluster, keeping results consistent. {opt impute(all)} goes further: after cluster
donation it fills any remaining blank with the variable's {it:observed minimum} anywhere
in the data {hline 2} always a real, type-valid code from your own data (for a marital
status coded 1 = single, the fill is 1) {hline 2} so markers are always complete and
{bf:every empty cluster is always retained}. That embodies the design-based view that a
sampled cluster should count regardless of item missingness among its non-subpopulation
members, but it diverges from the full-data {cmd:svy} run wherever the full data would
have dropped a cluster entirely.{p_end}

{p 4 8}{bf:Documented edge case.} If no single row in a cluster is complete on a
model's variable set but donors exist for each variable separately, the composite
marker retains that cluster while full-data {cmd:svy} would drop it (one extra
zero-total PSU: design df +1 and a slightly recentered stratum mean). The divergence
is tiny but real, which is why {opt impute} is off by default: without it, svyslim's
machine-precision equivalence guarantee holds unconditionally.{p_end}

{title:Two golden rules}

{p 4 8}{bf:(1)} On the slimmed file, always analyze with
{cmd:svy, subpop(}{it:subpopvar}{cmd:):} {hline 2} never plain {cmd:svy:}.
The marker rows must be excluded by {cmd:subpop()}; plain {cmd:svy:} would
wrongly include them.{p_end}

{p 4 8}{bf:(2)} Pass {opt complete()} listing every variable your models will
use. {cmd:svy} drops rows with missing values on model variables; if a marker
row were dropped that way, its PSU would vanish again. {cmd:svyslim} warns you
if some empty PSU had no fully observed row to use as a marker.{p_end}

{title:Typical workflow}

{p 8 12}{cmd:. use bigdata, clear}{space 18}// millions of rows, ONCE{p_end}
{p 8 12}{cmd:. svyset psu [pw=wt], strata(strat)}{p_end}
{p 8 12}{cmd:. svyslim mysubpop, complete(y x1 x2)}{p_end}
{p 8 12}{cmd:. svyslim mysubpop, complete(y x1 x2) totals}{space 4}// also preserves e(N_pop){p_end}
{p 8 12}{cmd:. save subpop_slim, replace}{space 11}// small file{p_end}
{p 8 12}{cmd:. }{p_end}
{p 8 12}{cmd:. use subpop_slim, clear}{space 13}// from now on: fast{p_end}
{p 8 12}{cmd:. svy, subpop(mysubpop): logit y x1 x2}{p_end}
{p 8 12}{cmd:. svy, subpop(mysubpop): melogit y x1 x2 || psu:}{p_end}

{p 4 8}For multilevel models, {cmd:svy:} rejects a [pw=] final-weight svyset
(error r(459)); re-svyset with stage weights and give {cmd:svyslim} the final
weight via {opt pweight()}:{p_end}

{p 8 12}{cmd:. svyset psu, strata(strat) || _n, weight(wt)}{p_end}
{p 8 12}{cmd:. svyslim mysubpop, complete(y x1 x2) pweight(wt)}{p_end}
{p 8 12}{cmd:. svy, subpop(mysubpop): melogit y x1 x2 || psu:}{p_end}

{p 4 8}Note that {cmd:mixed} is not svy-supported at all; use
{cmd:meglm ..., family(gaussian)} for multilevel linear regression.{p_end}

{p 4 8}For {cmd:stcox}, run {cmd:stset} again on the slimmed file before
{cmd:svy, subpop(): stcox} (weights come from {cmd:svyset}, not
{cmd:stset}).{p_end}

{title:When svyslim helps (and when it does not)}

{p 4 8}It shrinks the data only when PSUs are real clusters holding many
people (DHS, MICS, NHANES, NSFG, PISA, ...), so a scattered subpopulation
leaves whole clusters empty and only a few markers are needed. It does {bf:not}
help when each individual is their own PSU (BRFSS as usually {cmd:svyset}):
then every excluded person is an empty PSU and nearly everyone would become a
marker. If the subpopulation appears in every PSU, {cmd:keep} already matches
{cmd:svy, subpop()} and {cmd:svyslim} is simply not needed (it will add zero
markers).{p_end}

{title:Stored results}

{p 4 8}{cmd:svyslim} stores the following in {cmd:r()}:{p_end}

{synoptset 18 tabbed}{...}
{synopt:{cmd:r(N_full)}}rows before slimming{p_end}
{synopt:{cmd:r(N_subpop)}}subpopulation rows kept{p_end}
{synopt:{cmd:r(N_marker)}}marker rows added from empty PSUs{p_end}
{synopt:{cmd:r(N_kept)}}rows remaining in memory{p_end}
{synopt:{cmd:r(mode)}}{cmd:minimal} or {cmd:totals}{p_end}
{synopt:{cmd:r(impute)}}{cmd:on} or {cmd:off}{p_end}

{title:Verification}

{p 4 8}Run {cmd:svyslim_verify.do} (basic models), {cmd:svyslim_models_test.do}
(betareg, stcox, zip/zinb, tpoisson/tnbreg, multilevel, gsem), or
{cmd:svyslim_dhs_test.do} (real DHS practice data). In each, {bf:|b diff|} and
{bf:|se diff|} between the full-data and slimmed runs should be about 1e-6 or
smaller.{p_end}

{title:Remarks}

{p 4 8}This is a prototype developed and reasoned through carefully, with the
underlying statistics verified independently by simulation; validate on your
own design with the do-files above before relying on it. Multi-stage designs
are handled through the first-stage PSUs (which is what linearized survey
variance uses); {cmd:svyslim} does not adjust finite population corrections
at later stages.{p_end}

{title:Acknowledgment}

{p 4 8}The core idea {hline 2} retain the excluded rows' design skeleton so that
{cmd:svy, subpop()} on a reduced dataset reproduces the full-data result {hline 2}
was sketched by Austin Nichols on Statalist (24 Nov 2007), who noted that a
{cmd:-svysubset-} package would be tempting to write but was concerned that
model-specific missing-value patterns would defeat automation. {cmd:svyslim}
implements and generalizes his procedure; the {opt complete()} option addresses
the missing-value concern by letting the user declare the union of model variables
once. See: Nichols, A. 2007. Re: st: Svy subsamples. Statalist archive,
{browse "https://www.stata.com/statalist/archive/2007-11/msg00810.html"}.{p_end}

{title:Author}

{p 4 8}David Aduragbemi Okunlola{p_end}
{p 4 8}Email: {browse "mailto:okunloladavid4@gmail.com":okunloladavid4@gmail.com};
{browse "mailto:dao22@fsu.edu":dao22@fsu.edu}{p_end}

{title:See also}

{p 4 8}{helpb svy}, {helpb svyset}, {helpb svy estimation}{p_end}
