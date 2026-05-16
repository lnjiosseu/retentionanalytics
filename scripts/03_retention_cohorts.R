# =============================================================================
# RetentionAnalytics: 03_retention_cohorts.R — Cohort Retention & DAU/MAU
# =============================================================================

# Clear environment
rm(list = ls())

library(tidyverse)

users    <- read_csv("data/users.csv",    show_col_types = FALSE)
sessions <- read_csv("data/sessions.csv", show_col_types = FALSE)

# -----------------------------------------------------------------------------
# 1. Monthly retention curves — overall and by cohort
# -----------------------------------------------------------------------------
retention_cols <- paste0("active_month_", 1:12)

retention_long <- users %>%
  select(user_id, cohort_month, plan_type, power_user, all_of(retention_cols)) %>%
  pivot_longer(cols = all_of(retention_cols),
               names_to  = "month_label",
               values_to = "active") %>%
  mutate(months_since_signup = as.integer(str_extract(month_label, "\\d+")))

# Overall curve
retention_curve_overall <- retention_long %>%
  group_by(months_since_signup) %>%
  summarise(
    retention_rate = round(100 * mean(active), 2),
    n_active       = sum(active),
    .groups = "drop"
  )

cat("--- Overall Retention Curve ---\n")
print(retention_curve_overall)
write_csv(retention_curve_overall, "outputs/retention_curve_overall.csv")

# By plan type
retention_by_plan <- retention_long %>%
  group_by(plan_type, months_since_signup) %>%
  summarise(retention_rate = round(100 * mean(active), 2), .groups = "drop")

write_csv(retention_by_plan, "outputs/retention_by_plan.csv")

# Power user vs regular
retention_by_power <- retention_long %>%
  group_by(power_user, months_since_signup) %>%
  summarise(retention_rate = round(100 * mean(active), 2), .groups = "drop") %>%
  mutate(segment = ifelse(power_user == 1, "Power User", "Regular User"))

write_csv(retention_by_power, "outputs/retention_by_power.csv")

# Month 6 retention by cohort (key north star metric)
m6_retention <- retention_long %>%
  filter(months_since_signup == 6) %>%
  group_by(cohort_month) %>%
  summarise(
    m6_retention_rate = round(100 * mean(active), 2),
    n_users           = n(),
    .groups = "drop"
  )

cat("\n--- Month-6 Retention by Cohort ---\n")
print(m6_retention)
write_csv(m6_retention, "outputs/m6_retention_by_cohort.csv")

# -----------------------------------------------------------------------------
# 2. DAU / MAU trends
# -----------------------------------------------------------------------------
sessions <- sessions %>%
  mutate(
    year_month = format(session_date, "%Y-%m"),
    week       = format(session_date, "%Y-W%V")
  )

dau <- sessions %>%
  group_by(session_date) %>%
  summarise(dau = n_distinct(user_id), .groups = "drop")

mau <- sessions %>%
  group_by(year_month) %>%
  summarise(mau = n_distinct(user_id), .groups = "drop")

# DAU/MAU stickiness ratio (join on month)
dau_mau <- dau %>%
  mutate(year_month = format(session_date, "%Y-%m")) %>%
  left_join(mau, by = "year_month") %>%
  mutate(stickiness = round(100 * dau / mau, 2))

cat("\n--- Monthly DAU/MAU Summary ---\n")
dau_mau_summary <- dau_mau %>%
  group_by(year_month) %>%
  summarise(
    avg_dau    = round(mean(dau)),
    mau        = first(mau),
    avg_stickiness = round(mean(stickiness), 2),
    .groups = "drop"
  )
print(dau_mau_summary)
write_csv(dau_mau_summary, "outputs/dau_mau_summary.csv")
write_csv(dau, "outputs/daily_active_users.csv")

# -----------------------------------------------------------------------------
# 3. Session engagement trends
# -----------------------------------------------------------------------------
engagement_trend <- sessions %>%
  group_by(year_month) %>%
  summarise(
    total_sessions      = n(),
    avg_session_length  = round(mean(session_length_min), 2),
    avg_actions         = round(mean(actions_per_session), 2),
    .groups = "drop"
  )

cat("\n--- Engagement Trend ---\n")
print(engagement_trend)
write_csv(engagement_trend, "outputs/engagement_trend.csv")

cat("\nRetention cohort analysis complete.\n")
