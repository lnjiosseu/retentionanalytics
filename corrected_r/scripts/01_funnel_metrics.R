# RetentionAnalytics corrected pipeline: funnel metrics
# Run from the repository root after generating data/users.csv.
library(tidyverse)
dir.create("corrected_r/outputs", recursive = TRUE, showWarnings = FALSE)
users <- read_csv("data/users.csv", show_col_types = FALSE)
required <- c("user_id", "completed_signup", "completed_onboarding",
              "completed_activation", "completed_engagement", "completed_conversion",
              "plan_type", "acquisition_channel")
stopifnot(all(required %in% names(users)), !anyDuplicated(users$user_id))
steps <- c("Signup", "Onboarding", "Activation", "Engagement", "Conversion")
cols <- c("completed_signup", "completed_onboarding", "completed_activation",
          "completed_engagement", "completed_conversion")
counts <- map_dbl(cols, ~sum(users[[.x]] == 1, na.rm = TRUE))
funnel <- tibble(
  step = steps, users = as.integer(counts),
  pct_of_signups = 100 * counts / counts[1],
  step_conversion_pct = c(NA_real_, 100 * counts[-1] / counts[-length(counts)])
) |>
  mutate(drop_off_pct = 100 - step_conversion_pct)
write_csv(funnel, "corrected_r/outputs/funnel_overall.csv")
by_plan <- users |>
  group_by(plan_type) |>
  summarise(n_users = n(),
            onboarding_pct = 100 * mean(completed_onboarding == 1),
            activation_pct = 100 * mean(completed_activation == 1),
            engagement_pct = 100 * mean(completed_engagement == 1),
            conversion_pct = 100 * mean(completed_conversion == 1),
            .groups = "drop")
write_csv(by_plan, "corrected_r/outputs/funnel_by_plan.csv")
by_channel <- users |>
  group_by(acquisition_channel) |>
  summarise(n_users = n(),
            activation_pct = 100 * mean(completed_activation == 1),
            conversion_pct = 100 * mean(completed_conversion == 1),
            .groups = "drop") |>
  arrange(desc(conversion_pct))
write_csv(by_channel, "corrected_r/outputs/funnel_by_channel.csv")
