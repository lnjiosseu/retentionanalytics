# Corrected cohort retention and calendar-complete activity metrics.
rm(list = ls())
suppressPackageStartupMessages(library(tidyverse))
users <- read_csv("corrected_r/data/users.csv", show_col_types = FALSE)
sessions <- read_csv("corrected_r/data/sessions.csv", show_col_types = FALSE)
dir.create("corrected_r/outputs", recursive = TRUE, showWarnings = FALSE)

retention_cols <- paste0("active_month_", 1:12)
retention_long <- users |>
  select(user_id, cohort_month, plan_type, power_user, all_of(retention_cols)) |>
  pivot_longer(all_of(retention_cols), names_to = "month_label", values_to = "active") |>
  mutate(months_since_signup = as.integer(str_extract(month_label, "\\d+")))

overall <- retention_long |>
  group_by(months_since_signup) |>
  summarise(retention_rate_pct = 100 * mean(active),
            active_users = sum(active), eligible_users = n(), .groups = "drop")
write_csv(overall, "corrected_r/outputs/retention_curve_overall.csv")

by_plan <- retention_long |>
  group_by(plan_type, months_since_signup) |>
  summarise(retention_rate_pct = 100 * mean(active), eligible_users = n(),
            .groups = "drop")
write_csv(by_plan, "corrected_r/outputs/retention_by_plan.csv")

by_power <- retention_long |>
  group_by(power_user, months_since_signup) |>
  summarise(retention_rate_pct = 100 * mean(active), eligible_users = n(),
            .groups = "drop") |>
  mutate(segment = if_else(power_user == 1, "Power user", "Regular user"))
write_csv(by_power, "corrected_r/outputs/retention_by_power.csv")

m6 <- users |>
  group_by(cohort_month) |>
  summarise(m6_retention_pct = 100 * mean(active_month_6),
            cohort_size = n(), m6_active_users = sum(active_month_6),
            .groups = "drop")
write_csv(m6, "corrected_r/outputs/m6_retention_by_cohort.csv")

# Full calendar: zero-session days remain in DAU denominator.
date_min <- min(sessions$session_date)
date_max <- max(sessions$session_date)
calendar <- tibble(session_date = seq(date_min, date_max, by = "day"))
dau <- sessions |>
  group_by(session_date) |>
  summarise(dau = n_distinct(user_id), .groups = "drop") |>
  right_join(calendar, by = "session_date") |>
  mutate(dau = replace_na(dau, 0L),
         year_month = format(session_date, "%Y-%m"))
mau <- sessions |>
  mutate(year_month = format(session_date, "%Y-%m")) |>
  group_by(year_month) |>
  summarise(mau = n_distinct(user_id), .groups = "drop")
dau_mau <- dau |>
  left_join(mau, by = "year_month") |>
  mutate(stickiness_pct = if_else(mau > 0, 100 * dau / mau, NA_real_))
summary <- dau_mau |>
  group_by(year_month) |>
  summarise(avg_dau = mean(dau), mau = first(mau),
            avg_dau_mau_pct = mean(stickiness_pct, na.rm = TRUE),
            calendar_days = n(), .groups = "drop")
write_csv(dau, "corrected_r/outputs/daily_active_users.csv")
write_csv(summary, "corrected_r/outputs/dau_mau_summary.csv")

engagement <- sessions |>
  mutate(year_month = format(session_date, "%Y-%m")) |>
  group_by(year_month) |>
  summarise(sessions = n(),
            avg_session_length_min = mean(session_length_min),
            avg_actions_per_session = mean(actions_per_session),
            unique_active_users = n_distinct(user_id), .groups = "drop")
write_csv(engagement, "corrected_r/outputs/engagement_trend.csv")
cat("Corrected cohort and activity analysis complete.\n")
