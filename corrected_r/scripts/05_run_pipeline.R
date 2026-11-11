# Run the corrected RetentionAnalytics pipeline from the repository root.
source("corrected_r/scripts/01_funnel_metrics.R")
source("corrected_r/scripts/02_retention_metrics.R")
source("corrected_r/scripts/03_predictive_model.R")
source("corrected_r/scripts/04_ab_simulation.R")
message("Corrected RetentionAnalytics outputs generated in corrected_r/outputs/.")
