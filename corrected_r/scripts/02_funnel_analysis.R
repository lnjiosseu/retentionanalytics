# Corrected funnel analysis. Run from repository root.
rm(list = ls())
suppressPackageStartupMessages(library(tidyverse))
users <- read_csv("corrected_r/data/users.csv", show_col_types = FALSE)
dir.create("corrected_r/outputs", recursive = TRUE, showWarnings = FALSE)

steps <- c("Signup", "Onboarding", "Activation", "Engagement", "Conversion")
cols <- c("completed_signup", "completed_onboarding", "completed_activation",
          "completed_engagement", "completed_conversion")
counts <- map_int(cols, ~sum(users[[.x]], na.rm = TRUE))
funnel <- tibble(
  step = factor(steps, levels = steps),
  users = counts,
  pct_of_signups = 100 * counts / counts[1],
  step_conversion_pct = c(100, 100 * counts[-1] / counts[-length(counts)]),
  step_dropoff_pct = 100 - step_conversion_pct
) |>
  mutate(across(where(is.numeric), ~round(.x, 2)))
write_csv(funnel, "corrected_r/outputs/funnel_overall.csv")

by_plan <- users |>
  group_by(plan_type) |>
  summarise(n_users = n(),
            across(all_of(cols[-1]), ~100 * mean(.x), .names = "{.col}_pct"),
            .groups = "drop") |>
  mutate(across(where(is.numeric), ~round(.x, 2)))
write_csv(by_plan, "corrected_r/outputs/funnel_by_plan.csv")

by_channel <- users |>
  group_by(acquisition_channel) |>
  summarise(n_users = n(),
            activation_pct = 100 * mean(completed_activation),
            conversion_pct = 100 * mean(completed_conversion),
            .groups = "drop") |>
  mutate(across(where(is.numeric), ~round(.x, 2))) |>
  arrange(desc(conversion_pct))
write_csv(by_channel, "corrected_r/outputs/funnel_by_channel.csv")

dropoffs <- funnel |>
  filter(step != "Signup") |>
  arrange(desc(step_dropoff_pct))
write_csv(dropoffs, "corrected_r/outputs/funnel_dropoffs.csv")

# Scenario is a mechanical projection, not a causal estimate.
activation_rate <- mean(users$completed_activation)
engagement_given_activation <- sum(users$completed_engagement) /
  max(1, sum(users$completed_activation))
conversion_given_engagement <- sum(users$completed_conversion) /
  max(1, sum(users$completed_engagement))
improved_activation <- min(1, activation_rate + .05)
current_conversions <- nrow(users) * activation_rate *
  engagement_given_activation * conversion_given_engagement
scenario_conversions <- nrow(users) * improved_activation *
  engagement_given_activation * conversion_given_engagement
projection <- tibble(
  scenario = c("Observed baseline", "Illustrative +5 percentage-point activation"),
  activation_rate_pct = 100 * c(activation_rate, improved_activation),
  projected_conversions = c(current_conversions, scenario_conversions),
  relative_conversion_lift_pct = c(NA_real_,
    100 * (scenario_conversions / current_conversions - 1))
) |>
  mutate(across(where(is.numeric), ~round(.x, 2)))
write_csv(projection, "corrected_r/outputs/funnel_improvement_projection.csv")
cat("Corrected funnel analysis complete.\n")
