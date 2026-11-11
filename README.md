# RetentionAnalytics: Product Retention, Funnel & Experimentation Analytics

RetentionAnalytics is an end-to-end **R portfolio project** exploring acquisition funnels, product activation, lifecycle retention, engagement, baseline retention prediction, and experimentation using simulated product data. It combines cohort analysis, product metrics, statistical modeling, and an interactive Shiny dashboard with a reproducible Quarto report.

> **Data and scope:** All user, session, and experiment records are synthetic. Results are illustrative and do not describe a real product, customer population, or production system. Funnel scenarios are mechanical projections, and the experiment is independently simulated rather than drawn from the lifecycle dataset.

---

## Project objectives

Product analytics requires more than reporting a single conversion or retention rate. A useful workflow should make it possible to examine:

- Where users drop out of a sequential acquisition and conversion funnel.
- How retention changes over the customer lifecycle and across signup cohorts.
- How retention differs by plan and user engagement segment.
- How daily and monthly activity relate through DAU, MAU, and DAU/MAU.
- Whether first-month features provide useful signals for predicting month-6 retention.
- How a separately simulated experiment behaves when an assumed treatment effect decays over time.

This project brings these analyses together while distinguishing descriptive metrics, predictive associations, mechanical scenarios, and simulated experimental results.

## Dataset and evaluation design

The corrected pipeline generates **5,000 synthetic users** and session-level activity records. The latest reported run generated **92,072 session events**. User records include lifecycle, plan, acquisition, and behavioral attributes used in the funnel, cohort, engagement, and predictive analyses.

The project also generates an **independent simulated randomized experiment** with 1,251 observations per arm. Those experiment records are separate from the 5,000-user lifecycle dataset and use stipulated weekly retention probabilities.

Generated datasets and analysis outputs are written locally to `corrected_r/data/` and `corrected_r/outputs/`. They are not committed to the repository.

## Corrected results

The figures below reflect the latest reported run of the corrected R pipeline.

| Metric | Result | Interpretation |
|---|---:|---|
| Synthetic users | 5,000 | Lifecycle analysis population |
| Session events | 92,072 | Generated conditional on simulated monthly active status |
| Signup-to-conversion | 12.9% | Share of signups reaching the conversion stage |
| Overall month-6 retention | 31.26% | Share of eligible users active in month 6 |
| Retention-model test ROC-AUC | 0.567 | Weak held-out discrimination |
| Held-out test observations | 1,001 | Test partition used for final model evaluation |

At the validation-selected classification threshold of **0.346**, the month-6 retention model achieved **40.6% precision**, **32.9% recall**, **78.1% specificity**, and **63.9% accuracy** on the held-out test data. The ROC-AUC of 0.567 indicates limited ability to rank users by future retention in this synthetic dataset. This is a baseline modeling exercise, not a production-ready churn or retention model.

### Simulated experiment results

The independent experiment contains 1,251 observations in each arm.

| Period | Treatment minus control | One-sided p-value |
|---|---:|---:|
| Weeks 1-2 | +5.116 percentage points | <0.001 |
| Weeks 3-4 | +1.199 percentage points | 0.143 |

The weekly probabilities are stipulated simulation inputs. The early-versus-late comparison illustrates a decaying simulated treatment effect. It is not an empirical novelty-effect finding, and it should not be interpreted as an observed product experiment.

## Funnel analysis and activation scenario

The funnel is sequential. A user must complete a preceding stage to be counted in a later stage. The corrected overall funnel reports:

| Funnel stage | Users | Share of signups |
|---|---:|---:|
| Signup | 5,000 | 100.0% |
| Onboarding | 3,874 | 77.5% |
| Activation | 2,407 | 48.1% |
| Engagement | 1,387 | 27.7% |
| Conversion | 647 | 12.9% |

The illustrative activation scenario increases activation by five percentage points, from 48.1% to 53.1%, while holding downstream conditional conversion rates constant. It projects approximately **714 conversions**, a **10.4% relative lift** versus the baseline. This is a mechanical projection, not a causal estimate of what an intervention would achieve.

## Retention cohorts and product engagement

Retention is measured by **months since signup**, using the eligible simulated user cohort as the denominator. The dashboard includes retention curves by plan and by regular versus power-user segment, as well as month-6 retention by monthly signup cohort.

The engagement analysis includes:

- Daily active users (DAU) over a complete daily calendar, including zero-session days.
- Monthly active users (MAU), defined as distinct active users within each calendar month.
- DAU/MAU stickiness, calculated using the monthly MAU denominator and summarized across calendar days in each month.
- Monthly session counts, average session duration, average actions per session, and unique active users.

These measures are generated from the simulation rules. They are useful for demonstrating product analytics workflows, but should not be mistaken for observed customer behavior.

## Predictive modeling

The corrected predictive workflow uses logistic regression to predict month-6 retention from first-month profile and behavioral features. The workflow separates training, validation, and held-out test data. The classification threshold is selected on validation data, and final performance is reported once on the untouched test partition.

The test ROC-AUC of **0.567** is weak. Model coefficients describe associations under the synthetic data-generating process. They are not causal effects, and the model is not suitable for production targeting or customer-level decision-making.

## Interactive dashboard

The dashboard source is available in [`shiny/app.R`](shiny/app.R). It contains **five main navigation sections**, with two sub-tabs under Funnel Analysis, Retention & Engagement, and Predictive Model.

### Dashboard sections

1. **Executive Overview:** headline metrics, the overall conversion funnel, the overall retention curve, and interpretation of the synthetic-data scope.
2. **Funnel Analysis:** *Funnel Performance* presents the overall funnel, acquisition-channel conversion, and plan comparisons. *Drop-off & Scenarios* presents step-level conversion and drop-off plus the illustrative activation projection.
3. **Retention & Engagement:** *Retention & Cohorts* presents retention by plan and user segment plus month-6 signup-cohort comparisons. *Product Engagement* presents DAU/MAU, monthly session engagement, and daily active users.
4. **Predictive Model:** *Model Performance* presents held-out test metrics and their interpretation. *Feature Associations & Interpretation* presents logistic-regression coefficients with guidance on the log-odds scale.
5. **Experimentation:** results from the independent simulated randomized experiment, early-versus-later period tests, and explicit simulation assumptions.

### Dashboard gallery

The screenshots below allow the dashboard to be reviewed without running the app.

| Dashboard section | Screenshot |
|---|---|
| Executive Overview | ![Executive Overview](docs/screenshots/01-executive-overview.png) |
| Funnel Analysis: Funnel Performance | ![Funnel Performance](docs/screenshots/02-funnel-performance.png) |
| Funnel Analysis: Drop-off & Scenarios | ![Drop-off and Scenarios](docs/screenshots/03-funnel-dropoff-scenarios.png) |
| Retention & Engagement: Retention & Cohorts | ![Retention and Cohorts](docs/screenshots/04-retention-cohorts.png) |
| Retention & Engagement: Product Engagement | ![Product Engagement](docs/screenshots/05-product-engagement.png) |
| Predictive Model: Model Performance | ![Model Performance](docs/screenshots/06-model-performance.png) |
| Predictive Model: Feature Associations & Interpretation | ![Feature Associations](docs/screenshots/07-feature-associations.png) |
| Experimentation | ![Experimentation](docs/screenshots/08-experimentation.png) |

## Quarto analytical report

The reproducible report source is available in [`retentionanalytics_report.qmd`](retentionanalytics_report.qmd). It covers the conversion funnel, cohort retention, activity and engagement, predictive modeling, the independent experiment, limitations, and instructions for reproducing the analysis.

A rendered HTML report snapshot is also committed at [`retentionanalytics_report.html`](retentionanalytics_report.html). It can be opened or downloaded from the repository. The HTML file is a static report artifact, not a live dashboard or a GitHub Pages deployment.

To regenerate the report locally after running the four corrected analysis scripts:

```r
quarto::quarto_render("retentionanalytics_report.qmd")
```

Commit the regenerated HTML file when you want the repository's report snapshot to reflect updated analysis outputs.

## Repository structure

```
retentionanalytics/
├── corrected_r/
│   ├── scripts/
│   │   ├── 01_simulate_data.R
│   │   ├── 02_funnel_analysis.R
│   │   ├── 03_retention_cohorts.R
│   │   └── 04_predictive_model.R
│   ├── data/                         # Generated locally, not committed
│   └── outputs/                      # Generated locally, not committed
├── shiny/
│   └── app.R                         # Five-section Shiny dashboard
├── docs/
│   └── screenshots/                  # Dashboard screenshots
├── retentionanalytics_report.qmd     # Reproducible Quarto report source
├── retentionanalytics_report.html   # Committed rendered report snapshot
├── retentionanalytics.Rproj
└── README.md
```

The original implementation is retained at the repository root for historical reference. The `corrected_r/` pipeline is the source of truth for the corrected results described here.

## Reproducing the corrected analysis

Run commands from the repository root in a clean R session. Execute the scripts in order because later steps use data and outputs generated earlier.

```r
# Install required packages if needed
install.packages(c("tidyverse", "pROC", "shiny", "bslib", "bsicons", "scales"))

# 1. Simulate users and session events
source("corrected_r/scripts/01_simulate_data.R")

# 2. Build the sequential funnel and activation scenario
source("corrected_r/scripts/02_funnel_analysis.R")

# 3. Generate retention cohorts and engagement outputs
source("corrected_r/scripts/03_retention_cohorts.R")

# 4. Fit and evaluate the month-6 retention model
source("corrected_r/scripts/04_predictive_model.R")

# 5. Launch the Shiny dashboard
shiny::runApp("shiny/")

# 6. Render the Quarto report
quarto::quarto_render("retentionanalytics_report.qmd")
```

The scripts write generated input data to `corrected_r/data/` and analysis outputs to `corrected_r/outputs/`. These generated files are intentionally excluded from version control.

## Methods and tools

- **Language:** R
- **Data preparation and analysis:** tidyverse
- **Visualization:** ggplot2
- **Predictive modeling:** logistic regression
- **Model evaluation:** pROC and held-out classification metrics
- **Dashboard:** Shiny, bslib, bsicons, DT
- **Reporting:** Quarto

Key methodological choices include sequential funnel definitions, month-since-signup retention measurement, a complete daily calendar for DAU, validation-based threshold selection, held-out test evaluation, and explicit disclosure of the independent experiment's simulation assumptions.

## Limitations and next improvements

- All user, session, and experiment records are synthetic. The data-generating process is not calibrated to a real product or customer population.
- Retention is simulated at monthly intervals. Session activity is generated conditionally on simulated monthly active status and does not reproduce real-world session timing or product usage complexity.
- The predictive model is a baseline logistic regression with weak held-out discrimination. It is not a production churn or retention model.
- Model coefficients are associations under the synthetic data-generating process, not causal effects.
- The A/B experiment is independent of the lifecycle dataset and uses stipulated weekly probabilities. It is not a live or historical experiment.
- The activation scenario holds downstream conditional conversion rates constant. It is a mechanical projection, not an intervention-effect estimate.
- Revenue, acquisition cost, customer lifetime value, and unit economics are outside the current project scope.

## Author

**Ludovic Njiosseu** | MS in Statistics, NYU | Statistician and Data Scientist

Portfolio focus: product analytics, statistical modeling, experimentation, and applied data science.
