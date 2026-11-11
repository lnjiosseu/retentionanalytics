# RetentionAnalytics: User Retention & Funnel Analytics

A product analytics portfolio project in R covering conversion funnels, cohort retention, DAU/MAU, retention prediction, and experiment design using **synthetic data**.

## Scope and data provenance

The original committed simulation produces **5,000 synthetic users and 34,542 sessions**. These are the reproducible baseline inputs currently represented by the original scripts and saved outputs. The Nov. 9, 2026 PDF report describes a later analysis with different figures, including 92,072 sessions, 12.94% funnel conversion, 31.26% M6 retention, and model ROC-AUC 0.567. Those figures are preserved as results reported in that document, but the full generating pipeline and corresponding data files are not committed in this repository. They should not be represented as independently reproducible from the current main-branch scripts.

The earlier README claims of approximately 0.81 AUC, an 18 percentage-point causal power-user premium, and a statistically significant A/B lift are withdrawn. The original experiment code used arbitrary random offsets for its novelty comparison, so those outputs do not establish an empirical novelty effect.

## Analysis modules

- **Funnel:** signup, onboarding, activation, engagement, and conversion stages.
- **Cohorts:** monthly retention and M6 retention by signup cohort.
- **Engagement:** DAU/MAU and session activity summaries.
- **Prediction:** logistic regression for M6 retention. The original saved baseline AUC is **0.5946**, not 0.81. Treat it as weak predictive performance, not a deployable model.
- **Experiment design:** simulated A/B framework. Results are illustrative and are not evidence from a live product experiment.

## Baseline results currently traceable to the original saved outputs

| Metric | Original saved baseline |
|---|---:|
| Synthetic users | 5,000 |
| Sessions | 34,542 |
| Signup-to-conversion | 12.62% |
| Overall M6 retention | 31.96% |
| Retention model ROC-AUC | 0.5946 |
| DAU/MAU | Approximately 27.9% |

These values are historical baseline outputs, not the figures in the later Nov. 9 PDF report. Do not mix the two result sets.

## Corrected analysis work

The `audit/corrected-r-baseline` branch contains a separate `corrected_r/` area. It adds a complete daily DAU calendar, descriptive M6 segmentation, and a user-level randomized A/B simulation with a two-sided week-4 endpoint and confidence interval. It deliberately avoids publishing new model-performance claims until the complete pipeline has been run and reviewed. See [corrected analysis README](https://github.com/lnjiosseu/retentionanalytics/blob/audit/corrected-r-baseline/corrected_r/README.md).

## Reproduction

From the repository root, install the packages and run the original baseline scripts in order:

```r
install.packages(c("tidyverse", "pROC", "shiny", "bslib", "bsicons"))
source("scripts/01_simulate_data.R")
source("scripts/02_funnel_analysis.R")
source("scripts/03_retention_cohorts.R")
source("scripts/04_predictive_model.R")
```

The original Shiny app and Quarto report consume the original `data/` and `outputs/` files. They therefore display the original baseline, not the later Nov. 9 PDF analysis. Run them only after generating those files:

```r
shiny::runApp("shiny/")
quarto::quarto_render("retentionanalytics_report.qmd")
```

## Limitations

- All records are synthetic. No real consumer product or company data are used.
- The original model has weak discrimination (ROC-AUC 0.5946) and should not be described as production-ready.
- Power-user differences are descriptive associations in generated data, not causal effects.
- The original novelty-effect calculation is not a valid estimate because it uses arbitrary random offsets.
- The later PDF's differing metrics are not reproducible from the committed main-branch pipeline as currently published.

## Author

**Ludovic Njiosseu** | MPH (Biostatistics), NYU | Data Scientist & Statistician

5+ years across clinical research, pharmaceuticals, statistical analysis, and data science. Interested in product analytics, applied statistics, and machine learning.
