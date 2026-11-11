# RetentionAnalytics: Corrected R Baseline

This directory is a separate methodological correction to the original project. The original scripts, Shiny app, report, and historical outputs remain available for comparison.

## Data and provenance

The original committed simulation produces 5,000 synthetic users and 34,542 sessions. Its saved retention-model ROC-AUC is 0.5946. The Nov. 9, 2026 PDF report describes a different run with 92,072 sessions, 12.94% conversion, 31.26% M6 retention, and ROC-AUC 0.567. The complete data-generation code and matching generated data for that later report are not present in this branch. Therefore, those PDF figures are document-reported results, not results reproducible from this corrected directory as committed.

Do not combine values from the original saved outputs and the later PDF as if they came from one run.

## Corrected work currently implemented

- `scripts/01_retention_metrics.R`: computes M6 retention by power-user segment and a complete daily DAU calendar from the original users and sessions files.
- `scripts/02_ab_simulation.R`: creates a separate 5,000-user synthetic randomized experiment, generates user-level weekly retention outcomes, and reports a two-sided week-4 proportion test with a confidence interval.

These scripts do **not** constitute a complete replacement funnel, cohort, or predictive-model pipeline. No updated AUC or funnel claim is made from them. The experiment is a methodology demonstration with assumed treatment effects, not evidence of a real product intervention.

## Run

From the repository root, with the original generated data present:

```r
install.packages("tidyverse")
source("corrected_r/scripts/01_retention_metrics.R")
source("corrected_r/scripts/02_ab_simulation.R")
```

Outputs are written to `corrected_r/outputs/`. They are generated locally and are not committed.

## Remaining work before publishing a unified set of metrics

1. Commit or regenerate the exact data and complete scripts used for the Nov. 9 PDF.
2. Reconcile the PDF's 92,072-session run with the original 34,542-session baseline.
3. Build a complete corrected funnel, cohort, and first-month-only prediction pipeline.
4. Render the report and dashboard from the same generated outputs, then verify the figures agree.

Until those steps are complete, the original baseline and the later PDF results must remain explicitly separate.
