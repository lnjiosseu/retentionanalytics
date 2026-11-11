# RetentionAnalytics corrected pipeline: cohort retention and DAU/MAU
# Run from the repository root after generating data/users.csv and data/sessions.csv.
library(tidyverse)
dir.create("corrected_r/outputs", recursive = TRUE, showWarnings = FALSE)
users <- read_csv("data/users.csv", show_col_types = FALSE) |>
  mutate(cohort_month = as.Date(cohort_month))
sessions <- read_csv("data/sessions.csv", show_col_types = FALSE) |>
  mutate(session_date = as.Date(session_date))
stopifnot("active_month_6" %in% names(users),
          all(c("user_id", "session_date") %in% names(sessions)))
mcols <- paste0("active_month_", 1:12)
stopifnot(all(mcols %in% names(users)))
retention_long <- users |>
  select(user_id, cohort_month, plan_type, all_of(mcols)) |>
  pivot_longer(all_of(mcols), names_to = "month_label", values_to = "active") |>
  mutate(month_since_signup = as.integer(str_extract(month_label, "\\d+")))
retention_overall <- retention_long |>
  group_by(month_since_signup) |>
  summarise(users = n(), retained_users = sum(active == 1, na.rm = TRUE),
            retention_pct = 100 * mean(active == 1, na.rm = TRUE), .groups = "drop")
write_csv(retention_overall, "corrected_r/outputs/retention_overall.csv")
retention_by_cohort <- users |>
  group_by(cohort_month) |>
  summarise(cohort_users = n(),
            m6_retained = sum(active_month_6 == 1, na.rm = TRUE),
            m6_retention_pct = 100 * mean(active_month_6 == 1, na.rm = TRUE),
            .groups = "drop") |>
  arrange(cohort_month)
write_csv(retention_by_cohort, "corrected_r/outputs/m6_retention_by_cohort.csv")
retention_by_plan <- retention_long |>
  group_by(plan_type, month_since_signup) |>
  summarise(users = n(), retention_pct = 100 * mean(active == 1, na.rm = TRUE),
            .groups = "drop")
write_csv(retention_by_plan, "corrected_r/outputs/retention_by_plan.csv")
m6_segment <- users |>
  group_by(power_user) |>
  summarise(users = n(), m6_retained = sum(active_month_6 == 1, na.rm = TRUE),
            m6_retention_pct = 100 * mean(active_month_6 == 1, na.rm = TRUE),
            .groups = "drop")
write_csv(m6_segment, "corrected_r/outputs/m6_by_power_segment.csv")
if (nrow(sessions) > 0) {
  calendar <- tibble(session_date = seq(min(sessions$session_date),
                                        max(sessions$session_date), by = "day"))
  dau <- sessions |>
    distinct(session_date, user_id) |>
    count(session_date, name = "dau") |>
    right_join(calendar, by = "session_date") |>
    mutate(dau = replace_na(dau, 0L)) |>
    arrange(session_date)
  mau <- sessions |>
    mutate(year_month = format(session_date, "%Y-%m")) |>
    group_by(year_month) |>
    summarise(mau = n_distinct(user_id), .groups = "drop")
  dau_mau <- dau |>
    mutate(year_month = format(session_date, "%Y-%m")) |>
    left_join(mau, by = "year_month") |>
    mutate(stickiness_pct = if_else(mau > 0, 100 * dau / mau, NA_real_))
  monthly <- dau_mau |>
    group_by(year_month) |>
    summarise(avg_dau = mean(dau), mau = first(mau),
              avg_dau_mau_pct = mean(stickiness_pct, na.rm = TRUE),
              .groups = "drop")
  write_csv(dau, "corrected_r/outputs/daily_dau_calendar.csv")
  write_csv(monthly, "corrected_r/outputs/dau_mau_summary.csv")
} else {
  warning("No session records found; DAU/MAU outputs were not generated.")
}
