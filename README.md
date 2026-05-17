# RetentionAnalytics: User Retention & Funnel Analytics

A portfolio project replicating large-scale consumer product analytics workflows - built end-to-end in R, covering conversion funnel analysis, cohort retention modeling, DAU/MAU tracking, predictive power-user identification, and A/B experimentation design.

---

## Why This Project Exists

Retention and funnel analytics are the operational backbone of product data science. Understanding where users drop out of the funnel, which cohorts retain best, what behaviors predict long-term engagement, and how to design rigorous experiments to test interventions - these are the core questions product teams and growth teams answer every day.

This project builds that entire stack from first principles in R, with outputs designed for both technical stakeholders (model metrics, statistical test results) and non-technical ones (Shiny dashboards, self-serve KPI tracking).

---

## What It Does

**Module 1 - Data Simulation**
- 5,000 users across 12 monthly signup cohorts
- Acquisition channels, device types, plan types, and behavioral features
- Stochastic funnel completion and monthly retention with power-user boost

**Module 2 - Conversion Funnel**
- End-to-end funnel: signup → onboarding → activation → engagement → conversion
- Step-over-step drop-off identification - 3 critical intervention points flagged
- Conversion segmented by plan type and acquisition channel
- Projected activation lift scenario modeled downstream

**Module 3 - Retention Cohorts & DAU/MAU**
- Monthly retention curves by plan type and power-user segment
- Month-6 retention by signup cohort (north star metric)
- DAU/MAU stickiness ratio computed and trended over 3 months
- Session engagement metrics (session length, actions per session)

**Module 4 - Predictive Model & Experimentation**
- Logistic regression model predicting 6-month retention from first-month signals
- Power user behavioral signature extracted from feature importance
- Full A/B testing framework: hypothesis definition, power analysis, metric selection, novelty-effect correction, guardrail metric evaluation

**Deliverables**
- Interactive Shiny dashboard (4 tabs: Funnel, Retention, DAU/MAU, Prediction & Experimentation)
- Quarto HTML report with reproducible code, figures, and tables

---

## Key Results

| Finding | Value |
|---|---|
| Conversion rate (signup → conversion) | ~12% overall; ~35% for trial users |
| Top drop-off step | Onboarding → Activation |
| Projected lift from activation fix (+5pp) | ~12% downstream conversion lift |
| Power user M6 retention premium | ~18pp above regular users |
| Retention prediction AUC-ROC | ~0.81 |
| A/B experiment: onboarding lift | +5pp M1 retention (statistically significant) |

---

## Methods

| Component | Method |
|---|---|
| Funnel analysis | Step-over-step conversion rates, drop-off identification |
| Retention modeling | Monthly cohort retention matrix |
| DAU/MAU | Rolling distinct user counts by day/month |
| Power user prediction | Logistic regression on first-month behavioral features |
| Threshold selection | Youden's J |
| A/B power analysis | Two-proportion z-test |
| Novelty correction | Week 1–2 vs Week 3–4 lift comparison |
| Visualization | ggplot2, Shiny, bslib |

---

## Project Structure

```
retentionanalytics/
├── scripts/
│   ├── 01_simulate_data.R        # User + session dataset generation
│   ├── 02_funnel_analysis.R      # Funnel, drop-off, channel conversion
│   ├── 03_retention_cohorts.R    # Cohort curves, DAU/MAU, stickiness
│   └── 04_predictive_model.R     # Power user model, A/B framework
├── data/                         # Generated datasets (git-ignored)
├── outputs/                      # CSVs: metrics, segments, results (git-ignored)
├── shiny/
│   └── app.R                     # Interactive dashboard (4 tabs)
├── retentionanalytics_report.qmd # Quarto HTML report
└── README.md
```

---

## Reproducing the Project

```r
# Install dependencies
install.packages(c("tidyverse", "pROC", "shiny", "bslib", "bsicons"))

# Run in order from project root
source("scripts/01_simulate_data.R")
source("scripts/02_funnel_analysis.R")
source("scripts/03_retention_cohorts.R")
source("scripts/04_predictive_model.R")

# Launch dashboard
shiny::runApp("shiny/")

# Render report
quarto::quarto_render("retentionanalytics_report.qmd")
```

---

## Why This Matters for Product Teams

Retention and funnel analytics require a combination of statistical precision (correct cohort definition, valid A/B testing, novelty-effect awareness) and product intuition (which metrics matter, which drop-off points are actionable). This project demonstrates both - and delivers outputs in formats that serve data scientists, product managers, and leadership simultaneously.

---

## Author

**Ludovic Njiosseu** | MS Biostatistics, NYU | Data Scientist & Statistician  
5+ years across healthcare, pharma, financial analytics, and consumer products  
Open to roles in product analytics, growth data science, and applied ML
