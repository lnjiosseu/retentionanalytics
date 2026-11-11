# Synthetic randomized experiment. Method demonstration, not an observed product experiment.
library(tidyverse)
dir.create("corrected_r/outputs", recursive = TRUE, showWarnings = FALSE)
set.seed(2026)
n <- 5000L
experiment <- tibble(
  user_id = sprintf("EXP%05d", seq_len(n)),
  treatment = sample(rep(c(0L, 1L), length.out = n)),
  baseline_p = runif(n, 0.55, 0.80)
) |>
  mutate(
    week1 = rbinom(n(), 1, pmin(0.99, baseline_p + treatment * 0.06)),
    week2 = rbinom(n(), 1, pmin(0.99, baseline_p + treatment * 0.05)),
    week3 = rbinom(n(), 1, pmin(0.99, baseline_p + treatment * 0.03)),
    week4 = rbinom(n(), 1, pmin(0.99, baseline_p + treatment * 0.03))
  )
weekly <- experiment |>
  pivot_longer(starts_with("week"), names_to = "week", values_to = "retained") |>
  group_by(treatment, week) |>
  summarise(users = n(), retained = sum(retained),
            retention_pct = 100 * mean(retained), .groups = "drop")
write_csv(weekly, "corrected_r/outputs/ab_weekly_retention.csv")
control <- filter(experiment, treatment == 0)
treated <- filter(experiment, treatment == 1)
primary <- prop.test(c(sum(treated$week4), sum(control$week4)),
                     c(nrow(treated), nrow(control)),
                     alternative = "two.sided", correct = FALSE)
primary_result <- tibble(
  endpoint = "Week 4 retention (primary)",
  control_rate = mean(control$week4),
  treatment_rate = mean(treated$week4),
  risk_difference = mean(treated$week4) - mean(control$week4),
  ci_low = primary$conf.int[1], ci_high = primary$conf.int[2],
  p_value = primary$p.value, n_control = nrow(control), n_treatment = nrow(treated)
)
write_csv(primary_result, "corrected_r/outputs/ab_primary_result.csv")
period <- experiment |>
  mutate(early = (week1 + week2) / 2,
         late = (week3 + week4) / 2) |>
  group_by(treatment) |>
  summarise(early_rate = mean(early), late_rate = mean(late), .groups = "drop")
novelty <- tibble(
  period = c("Weeks 1-2", "Weeks 3-4"),
  treatment_control_difference = c(
    period$early_rate[period$treatment == 1] - period$early_rate[period$treatment == 0],
    period$late_rate[period$treatment == 1] - period$late_rate[period$treatment == 0]
  )
)
write_csv(novelty, "corrected_r/outputs/ab_novelty_comparison.csv")
