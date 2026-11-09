# =============================================================================
# RetentionAnalytics | Corrected R pipeline
# 01_simulate_data.R
#
# Generates synthetic users, 12-month retention outcomes, and session events
# that are conditional on each user's monthly active status.
# Run from the repository root.
# =============================================================================

rm(list = ls())
set.seed(2026)

suppressPackageStartupMessages(library(tidyverse))

N_USERS <- 5000L
cohort_months <- seq(as.Date("2023-01-01"), as.Date("2023-12-01"), by = "month")

users <- tibble(
  user_id = paste0("U", str_pad(seq_len(N_USERS), 5, pad = "0")),
  cohort_month = sample(
    cohort_months, N_USERS, replace = TRUE,
    prob = c(0.06, 0.07, 0.08, 0.09, 0.10, 0.11,
             0.10, 0.10, 0.09, 0.08, 0.07, 0.05)
  ),
  acquisition_channel = sample(
    c("organic", "paid_search", "social", "referral", "email"),
    N_USERS, replace = TRUE, prob = c(.30, .25, .20, .15, .10)
  ),
  device_type = sample(
    c("mobile", "desktop", "tablet"), N_USERS,
    replace = TRUE, prob = c(.55, .35, .10)
  ),
  plan_type = sample(
    c("free", "trial", "paid"), N_USERS,
    replace = TRUE, prob = c(.60, .25, .15)
  ),
  age_group = sample(
    c("18-24", "25-34", "35-44", "45+"), N_USERS,
    replace = TRUE, prob = c(.20, .35, .28, .17)
  )
)

# Funnel outcomes are sequential: a user cannot complete a later step
# without completing the preceding step.
rate_for_plan <- function(plan, base, trial, paid) {
  case_when(plan == "paid" ~ paid, plan == "trial" ~ trial, TRUE ~ base)
}

users <- users |>
  mutate(
    completed_signup = 1L,
    completed_onboarding = rbinom(
      N_USERS, 1, rate_for_plan(plan_type, .72, .80, .92)
    ),
    completed_activation = rbinom(
      N_USERS, 1, completed_onboarding *
        rate_for_plan(plan_type, .55, .65, .85)
    ),
    completed_engagement = rbinom(
      N_USERS, 1, completed_activation *
        rate_for_plan(plan_type, .48, .55, .78)
    ),
    completed_conversion = rbinom(
      N_USERS, 1, completed_engagement *
        rate_for_plan(plan_type, .12, .35, 1.00)
    )
  )

# A latent engagement propensity creates realistic within-user persistence.
# It is used only to generate synthetic outcomes, not as a model feature.
latent_engagement <- rnorm(N_USERS, 0, 0.45) +
  0.45 * users$completed_engagement +
  0.20 * (users$plan_type == "paid") +
  0.10 * (users$acquisition_channel == "referral")

users$power_user <- as.integer(
  latent_engagement >= quantile(latent_engagement, .80)
)

base_curve <- c(.70, .55, .44, .36, .30, .26,
                .23, .21, .19, .18, .17, .16)
retention_matrix <- matrix(
  0L, nrow = N_USERS, ncol = length(base_curve),
  dimnames = list(NULL, paste0("active_month_", seq_along(base_curve)))
)

for (m in seq_along(base_curve)) {
  logit_p <- qlogis(base_curve[m]) +
    0.65 * users$power_user +
    0.35 * (users$plan_type == "paid") +
    0.12 * (users$plan_type == "trial") +
    0.10 * (users$completed_engagement == 1)
  p_active <- plogis(logit_p)
  retention_matrix[, m] <- rbinom(N_USERS, 1, p_active)
}
users <- bind_cols(users, as_tibble(retention_matrix))

# Generate session events only during months in which the user is active.
# Each user receives a 12-month follow-up window after their signup month.
# A zero-session calendar day is retained later when DAU is aggregated.
session_parts <- vector("list", N_USERS)
for (i in seq_len(N_USERS)) {
  uid <- users$user_id[i]
  for (m in seq_along(base_curve)) {
    if (users[[paste0("active_month_", m)]][i] == 0L) next

    month_start <- seq(users$cohort_month[i], by = "month", length.out = 12)[m]
    month_end <- seq(month_start, by = "month", length.out = 2)[2] - 1
    dates <- seq(month_start, month_end, by = "day")

    # Active users have a daily visit probability; power users visit more often.
    daily_p <- if (users$power_user[i] == 1L) .22 else .11
    active_dates <- dates[rbinom(length(dates), 1, daily_p) == 1L]
    if (length(active_dates) == 0L) next

    session_parts[[i]] <- bind_rows(
      session_parts[[i]],
      tibble(
        user_id = uid,
        session_date = active_dates,
        session_length_min = round(pmax(.5, rnorm(length(active_dates), 8, 4)), 1),
        actions_per_session = rpois(length(active_dates), ifelse(
          users$power_user[i] == 1L, 6, 4
        ))
      )
    )
  }
}
sessions <- bind_rows(session_parts) |>
  arrange(session_date, user_id) |>
  mutate(session_id = paste0("S", str_pad(row_number(), 7, pad = "0"))) |>
  select(session_id, everything())

dir.create("corrected_r/data", recursive = TRUE, showWarnings = FALSE)
write_csv(users, "corrected_r/data/users.csv")
write_csv(sessions, "corrected_r/data/sessions.csv")

cat(sprintf("Users: %d | Session events: %d\n", nrow(users), nrow(sessions)))
cat(sprintf("Overall M6 retention: %.2f%%\n",
            100 * mean(users$active_month_6)))
cat("Saved corrected_r/data/users.csv and corrected_r/data/sessions.csv\n")
