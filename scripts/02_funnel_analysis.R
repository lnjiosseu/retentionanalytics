# =============================================================================
# RetentionAnalytics: 02_funnel_analysis.R — Conversion Funnel & Drop-off
# =============================================================================

# Clear environment
rm(list = ls())

library(tidyverse)

users <- read_csv("data/users.csv", show_col_types = FALSE)
dir.create("outputs", showWarnings = FALSE)

# -----------------------------------------------------------------------------
# 1. Overall funnel
# -----------------------------------------------------------------------------
funnel_overall <- tibble(
  step  = c("Signup", "Onboarding", "Activation", "Engagement", "Conversion"),
  col   = c("completed_signup", "completed_onboarding", "completed_activation",
            "completed_engagement", "completed_conversion"),
  n     = c(sum(users$completed_signup), sum(users$completed_onboarding),
            sum(users$completed_activation), sum(users$completed_engagement),
            sum(users$completed_conversion))
) %>%
  mutate(
    pct_of_signup   = round(100 * n / n[1], 1),
    step_conversion = round(100 * n / lag(n), 1),
    drop_off_pct    = round(100 - step_conversion, 1)
  )

cat("--- Overall Funnel ---\n")
print(funnel_overall)
write_csv(funnel_overall, "outputs/funnel_overall.csv")

# -----------------------------------------------------------------------------
# 2. Funnel by plan type
# -----------------------------------------------------------------------------
funnel_by_plan <- users %>%
  group_by(plan_type) %>%
  summarise(
    n_users       = n(),
    pct_onboarding = round(100 * mean(completed_onboarding), 1),
    pct_activation = round(100 * mean(completed_activation), 1),
    pct_engagement = round(100 * mean(completed_engagement), 1),
    pct_conversion = round(100 * mean(completed_conversion), 1),
    .groups = "drop"
  )

cat("\n--- Funnel by Plan Type ---\n")
print(funnel_by_plan)
write_csv(funnel_by_plan, "outputs/funnel_by_plan.csv")

# -----------------------------------------------------------------------------
# 3. Funnel by acquisition channel
# -----------------------------------------------------------------------------
funnel_by_channel <- users %>%
  group_by(acquisition_channel) %>%
  summarise(
    n_users        = n(),
    pct_activation = round(100 * mean(completed_activation), 1),
    pct_conversion = round(100 * mean(completed_conversion), 1),
    .groups = "drop"
  ) %>%
  arrange(desc(pct_conversion))

cat("\n--- Conversion by Acquisition Channel ---\n")
print(funnel_by_channel)
write_csv(funnel_by_channel, "outputs/funnel_by_channel.csv")

# -----------------------------------------------------------------------------
# 4. Drop-off analysis — identify 3 critical drop points
# -----------------------------------------------------------------------------
drop_off <- funnel_overall %>%
  filter(!is.na(drop_off_pct)) %>%
  arrange(desc(drop_off_pct)) %>%
  select(step, n, pct_of_signup, step_conversion, drop_off_pct)

cat("\n--- Top Drop-off Points ---\n")
print(drop_off)
write_csv(drop_off, "outputs/funnel_dropoffs.csv")

# Project activation improvement (e.g. +5pp at activation → downstream lift)
current_activation <- funnel_overall$pct_of_signup[funnel_overall$step == "Activation"] / 100
improved_activation <- current_activation + 0.05

engagement_rate   <- funnel_overall$n[funnel_overall$step == "Engagement"] /
                     funnel_overall$n[funnel_overall$step == "Activation"]
conversion_rate   <- funnel_overall$n[funnel_overall$step == "Conversion"] /
                     funnel_overall$n[funnel_overall$step == "Engagement"]

projected_conversions_current  <- nrow(users) * current_activation * engagement_rate * conversion_rate
projected_conversions_improved <- nrow(users) * improved_activation * engagement_rate * conversion_rate
projected_lift_pct <- round(
  (projected_conversions_improved - projected_conversions_current) /
  projected_conversions_current * 100, 1)

cat(sprintf("\nProjected conversion lift from +5pp activation fix: %.1f%%\n", projected_lift_pct))

improvement_tbl <- tibble(
  scenario              = c("Current", "With +5pp Activation Fix"),
  activation_rate       = round(c(current_activation, improved_activation) * 100, 1),
  projected_conversions = round(c(projected_conversions_current, projected_conversions_improved)),
  projected_lift_pct    = c(NA, projected_lift_pct)
)
write_csv(improvement_tbl, "outputs/funnel_improvement_projection.csv")

cat("\nFunnel analysis complete.\n")
