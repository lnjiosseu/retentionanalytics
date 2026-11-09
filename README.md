# RetentionAnalytics: Product Retention, Funnel & Experimentation

An end-to-end R portfolio project demonstrating synthetic product analytics workflows: conversion funnels, cohort retention, engagement measurement, logistic-regression evaluation, and randomized experiment analysis.

> **Data disclosure:** All user, transaction, session, and experiment records in this repository are simulated. Results are illustrative and are not evidence about a real product or customer population.

## What the project demonstrates

1. Sequential funnel construction and segment-level conversion analysis.
2. Cohort-based month-since-signup retention measurement.
3. DAU, MAU, DAU/MAU stickiness, and session engagement.
4. A leakage-aware M6 retention prediction workflow with train, validation, and held-out test partitions.
5. A separately simulated randomized experiment with explicit assumptions and early-versus-late outcome analysis.
6. An interactive Shiny dashboard and reproducible Quarto report.

## Corrected pipeline

The original scripts and implementation are retained unchanged at the repository root for historical reference. The audited implementation is in `corrected_r/`.

```
corrected_r/
  scripts/
    01_simulate_data.R
    02_funnel_analysis.R
    03_retention_cohorts.R
    04_predictive_model.R
  data/       # generated, not committed
  outputs/    # generated, not committed
shiny/
  app.R
retentionanalytics_report.qmd
```

### Key methodological decisions

- Session events are generated only during a user's simulated active retention months. This links lifecycle retention and activity data.
- Funnel steps are sequential. Each later step requires completion of the preceding step.
- Retention is indexed by months since signup, not calendar month.
- DAU uses a complete daily calendar, including days with zero sessions. MAU is the distinct active-user count within each calendar month.
- The retention model uses first-month behavioral and profile features. The M6 target is excluded from predictors. Threshold selection occurs on validation data; final metrics are computed on a held-out test set.
- The A/B experiment is a separate synthetic randomized experiment. Week-level outcomes are simulated under stated probabilities. The early/late comparison is an illustration of a stipulated decaying treatment effect, not a measured novelty effect.
- The activation scenario is a mechanical projection holding downstream conditional rates constant. It is not a causal estimate.

## Reproduce

Run these commands from the repository root in a clean R session:

```r
install.packages(c("tidyverse", "pROC", "shiny", "bslib", "bsicons", "scales"))

source("corrected_r/scripts/01_simulate_data.R")
source("corrected_r/scripts/02_funnel_analysis.R")
source("corrected_r/scripts/03_retention_cohorts.R")
source("corrected_r/scripts/04_predictive_model.R")

shiny::runApp("shiny/")
quarto::quarto_render("retentionanalytics_report.qmd")
```

The scripts write generated data to `corrected_r/data/` and analysis outputs to `corrected_r/outputs/`. These generated files are intentionally excluded from version control. Run the pipeline in order before launching the dashboard or rendering the report.

## Interpreting the results

Do not interpret simulated metrics as production benchmarks. Predictive performance is conditional on the data-generating process. Logistic-regression coefficients describe associations in this synthetic dataset, not causal drivers of retention. The experiment's statistical tests describe one simulated assignment and outcome realization; they do not establish that an actual onboarding intervention works.

## Limitations

- The data-generating process is designed for demonstration and does not represent a calibrated real-world product.
- Retention is simulated at monthly intervals, while session activity is simulated at daily intervals conditional on those monthly outcomes.
- The predictive model is a baseline logistic regression, not a production churn system.
- The A/B experiment is independent of the 5,000-user lifecycle dataset and uses assumed weekly probabilities.
- No revenue, customer lifetime value, acquisition cost, or unit economics are modeled.

## Author

Ludovic Njiosseu | MS Statistics, NYU | Statistician and Data Scientist
