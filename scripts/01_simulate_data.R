# =============================================================================
# RetentionAnalytics: User Retention & Funnel Analytics
# 01_simulate_data.R — Simulate user cohort and event data
# =============================================================================

# Clear environment
rm(list = ls())

set.seed(42)
library(tidyverse)

N_USERS <- 5000

# Signup cohorts (monthly)
cohort_months <- seq(as.Date("2023-01-01"), as.Date("2023-12-01"), by = "month")

users <- tibble(
  user_id      = paste0("U", str_pad(1:N_USERS, 5, pad = "0")),
  cohort_month = sample(cohort_months, N_USERS, replace = TRUE,
                        prob = c(0.06, 0.07, 0.08, 0.09, 0.10,
                                 0.11, 0.10, 0.10, 0.09, 0.08, 0.07, 0.05)),
  acquisition_channel = sample(
    c("organic", "paid_search", "social", "referral", "email"),
    N_USERS, replace = TRUE, prob = c(0.30, 0.25, 0.20, 0.15, 0.10)
  ),
  device_type  = sample(c("mobile", "desktop", "tablet"), N_USERS,
                        replace = TRUE, prob = c(0.55, 0.35, 0.10)),
  plan_type    = sample(c("free", "trial", "paid"), N_USERS,
                        replace = TRUE, prob = c(0.60, 0.25, 0.15)),
  age_group    = sample(c("18-24", "25-34", "35-44", "45+"), N_USERS,
                        replace = TRUE, prob = c(0.20, 0.35, 0.28, 0.17))
)

# Funnel steps: signup → onboarding → activation → engagement → conversion
# Each step has a conditional pass-through rate
funnel_steps <- c("signup", "onboarding", "activation", "engagement", "conversion")

pass_rates <- list(
  onboarding  = list(base = 0.72, paid = 0.92, trial = 0.80),
  activation  = list(base = 0.55, paid = 0.85, trial = 0.65),
  engagement  = list(base = 0.48, paid = 0.78, trial = 0.55),
  conversion  = list(base = 0.12, paid = 1.00, trial = 0.35)
)

get_rate <- function(plan, step_rates) {
  case_when(
    plan == "paid"  ~ step_rates$paid,
    plan == "trial" ~ step_rates$trial,
    TRUE            ~ step_rates$base
  )
}

users <- users %>%
  mutate(
    completed_signup     = 1L,
    completed_onboarding = rbinom(N_USERS, 1, get_rate(plan_type, pass_rates$onboarding)),
    completed_activation = rbinom(N_USERS, 1,
      completed_onboarding * get_rate(plan_type, pass_rates$activation)),
    completed_engagement = rbinom(N_USERS, 1,
      completed_activation * get_rate(plan_type, pass_rates$engagement)),
    completed_conversion = rbinom(N_USERS, 1,
      completed_engagement * get_rate(plan_type, pass_rates$conversion))
  )

# Retention: probability of being active at each month post-signup
# Power users: high engagement users with higher baseline retention
users <- users %>%
  mutate(
    power_user_score = round(
      0.3 * completed_engagement +
      0.2 * (plan_type == "paid") +
      0.15 * (acquisition_channel == "referral") +
      0.1 * (device_type == "desktop") +
      rnorm(N_USERS, 0, 0.1), 4),
    power_user = as.integer(power_user_score >= quantile(power_user_score, 0.80))
  )

# Monthly retention matrix (12 months post-signup)
# Base retention curve follows a shifted negative binomial decay
retention_matrix <- matrix(0L, nrow = N_USERS, ncol = 12)
colnames(retention_matrix) <- paste0("active_month_", 1:12)

base_curve <- c(0.70, 0.55, 0.44, 0.36, 0.30, 0.26, 0.23, 0.21, 0.19, 0.18, 0.17, 0.16)
power_boost <- 0.18

for (m in 1:12) {
  p_active <- ifelse(
    users$power_user == 1,
    pmin(1, base_curve[m] + power_boost),
    base_curve[m]
  )
  # Paid users retain better
  p_active <- p_active + 0.10 * (users$plan_type == "paid")
  p_active <- pmin(1, p_active)
  retention_matrix[, m] <- rbinom(N_USERS, 1, p_active)
}

users <- bind_cols(users, as_tibble(retention_matrix))

# Session-level data (for DAU/MAU computation)
# Generate ~3 months of daily session logs
session_dates <- seq(as.Date("2024-01-01"), as.Date("2024-03-31"), by = "day")

# Each active user has sessions with probability proportional to engagement
active_user_ids <- users$user_id[users$completed_engagement == 1]
sessions <- map_dfr(active_user_ids, function(uid) {
  base_p  <- 0.15 + 0.20 * users$power_user[users$user_id == uid]
  active_days <- session_dates[rbinom(length(session_dates), 1, base_p) == 1]
  if (length(active_days) == 0) return(NULL)
  tibble(
    user_id      = uid,
    session_date = active_days,
    session_length_min = round(abs(rnorm(length(active_days), 8, 4)), 1),
    actions_per_session = rpois(length(active_days), 4)
  )
})

cat(sprintf("Users: %d | Sessions: %d\n", nrow(users), nrow(sessions)))
cat(sprintf("Conversion rate: %.2f%%\n", 100 * mean(users$completed_conversion)))
cat(sprintf("Power users: %.1f%%\n", 100 * mean(users$power_user)))

dir.create("data", showWarnings = FALSE)
write_csv(users,    "data/users.csv")
write_csv(sessions, "data/sessions.csv")
cat("Saved: data/users.csv, data/sessions.csv\n")
