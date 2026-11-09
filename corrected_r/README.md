# RetentionAnalytics: Corrected R Baseline

This folder is separate from the original implementation. Original scripts, Shiny app, report, and historical outputs remain unchanged.

## Data and claims
The supplied project uses 5,000 simulated users and 34,542 sessions, not 500K+ users. Historical retention-model AUC is 0.5946, not approximately 0.81. The power-user M6 difference is a descriptive association induced in simulated data, not a causal effect.

## Corrected methodology
- Explicitly label all data and experimental results as synthetic.
- Report power-user retention as a descriptive segment comparison.
- Use chronological cohort validation for prediction and exclude full-lifecycle variables unavailable at the prediction cutoff.
- Build a complete daily calendar for DAU, including zero-session days.
- Assign experiment users randomly and generate user-level weekly outcomes.
- Compute novelty effects from actual simulated weekly outcomes, never arbitrary random offsets.
- Report confidence intervals and a two-sided primary endpoint test.

Run the scripts from repository root. New outputs go only to `corrected_r/outputs/`. No new performance claims should be published until execution and review.
