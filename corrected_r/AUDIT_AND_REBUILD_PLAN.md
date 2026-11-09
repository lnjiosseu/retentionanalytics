# Corrected R implementation: RetentionAnalytics

This directory is a new, separate implementation. The original scripts and their historical outputs remain unchanged.

## Evidence-based baseline

The supplied source and output files describe 5,000 simulated users and 34,542 sessions. Saved outputs report 31.96% month-six retention overall, 51.75% for the power-user segment, and 27.01% for regular users (a 24.74 percentage-point descriptive difference). These are simulation outputs, not causal effects.

The saved retention-model AUC is 0.5946. The README claim of approximately 0.81 is not supported by the supplied output.

## Corrections required

1. Preserve funnel and cohort analyses, but define denominators and cohort maturity explicitly.
2. Make the data-generating process coherent: user-month activity indicators and session events must derive from the same latent activity process, or be clearly labeled as separate simulations.
3. Calculate DAU on a complete calendar, including zero-activity days; define MAU as distinct active users in a calendar month and state the DAU/MAU aggregation convention.
4. Define the prediction use case and prediction timestamp. Every feature must be available at that timestamp. Exclude future or contemporaneous leakage such as a power-user score defined using later behavior.
5. Use a chronological or cohort-based holdout where the data support it. Report ROC-AUC, PR-AUC, calibration, confusion matrix, sensitivity, specificity, precision, and confidence intervals where appropriate.
6. Rebuild the A/B experiment with user-level random assignment, recorded treatment exposure, and outcomes measured on those same assigned users.
7. Simulate weekly outcomes at user level if a novelty/persistence analysis is included. Compare prespecified periods and report uncertainty; do not add random noise to an aggregate lift.
8. Distinguish a simulated experiment from a real product experiment and avoid claiming causal impact outside the simulation.
9. Recalculate funnel improvement projections as explicit scenarios, not observed lifts.

## Reproducibility contract

- Inputs: `data/users.csv` and `data/sessions.csv` at the repository root.
- Outputs: `corrected_r/outputs/`.
- All random operations use explicit seeds.
- Model validation, experiment assignment, and outcome definitions are documented.
- No performance or causal claim is published until the corrected scripts have been run and their outputs reviewed.

## Current status

This folder is an audit/rebuild specification. Corrected executable scripts and verified metrics will be added after implementation and execution testing. The original `scripts/`, `shiny/`, report, and historical outputs are not modified by this work.
