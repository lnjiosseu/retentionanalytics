# RetentionAnalytics: Product Retention & Funnel Analysis

A product analytics case study using synthetic user and session data. The project examines acquisition-to-conversion funnel performance, cohort retention, DAU/MAU engagement, a six-month retention classifier, and an illustrative onboarding experiment.

## Data and scope

All records are synthetic. The November 9, 2026 analysis report describes 5,000 users across 12 signup cohorts. These results are not observations from a real product.

## Reported analysis snapshot

The following figures are transcribed from the November 9, 2026 analytical report. They are report-reported results, not a claim that the currently committed scripts regenerate every figure.

### Funnel

| Stage | Users | Share of signups |
|---|---:|---:|
| Signup | 5,000 | 100.00% |
| Onboarding | 3,874 | 77.48% |
| Activation | 2,407 | 48.14% |
| Engagement | 1,387 | 27.74% |
| Conversion | 647 | 12.94% |

### Retention and engagement

- Month-6 retention: 1,563 / 5,000 (31.26%).
- The report includes daily and monthly active-user summaries. Interpret DAU/MAU as engagement measures for the simulated observation window, not a generalizable product benchmark.

### Retention prediction

The report describes a logistic-regression model using first-month features and a held-out test set of 1,001 users.

| Metric | Reported value |
|---|---:|
| ROC-AUC | 0.567 |
| Precision | 0.406 |
| Recall | 0.329 |
| Specificity | 0.781 |
| Accuracy | 0.639 |
| Classification threshold | 0.346 |

The discrimination is modest. The model should be treated as a baseline, not as a strong production predictor.

### Illustrative onboarding experiment

The report describes a separate simulated experiment with 1,251 users per arm. The reported early-period treatment-control difference was +5.116 percentage points (one-sided p < 0.001); the later-period difference was +1.199 percentage points (one-sided p = 0.143). This is a simulation under assumed outcome probabilities, not a real randomized product experiment. The early/late contrast is not evidence of a measured causal novelty effect in production.

## Reproducibility and provenance

The repository retains the original analysis in `scripts/` and the audited baseline work in `corrected_r/`. The original saved outputs and the November 9 report do not agree on several quantities, including session volume, conversion, month-6 retention, and model AUC. The corrected branch currently contains focused methodological scripts, but not a complete end-to-end pipeline that regenerates every table in the November 9 report.

For that reason:
- The November 9 report is treated as the current **reported snapshot** for this branch.
- The historical original outputs are not silently substituted for the report values.
- No claim is made that the report snapshot is fully reproducible from the committed scripts today.
- The A/B simulation is kept separate from the 5,000-user observational simulation.
- No causal claim is made from the power-user/regular-user retention contrast.

See [corrected_r/README.md](corrected_r/README.md) for the audited script inventory and limitations.

## Project structure

```
retentionanalytics/
├── scripts/                         # Original project implementation
├── corrected_r/
│   ├── README.md                     # Audit notes and corrected methodology
│   └── scripts/                      # Focused corrected analysis scripts
├── shiny/
│   └── app.R                         # Report-snapshot dashboard
├── retentionanalytics_report.qmd     # Report-snapshot analytical report
└── README.md
```

## Tools and methods

R, tidyverse, ggplot2, Shiny, logistic regression, funnel conversion, cohort retention, DAU/MAU, classification metrics, two-proportion testing, and simulation.

## Author

**Ludovic Njiosseu** | MPH in Biostatistics, NYU | Data Scientist & Statistician  
5+ years across healthcare, pharma, statistical analysis, and applied data science.
