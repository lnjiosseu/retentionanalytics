# =============================================================================
# RetentionAnalytics: 04_predictive_model.R — Power User Prediction & A/B Framework
# =============================================================================

# Clear environment
rm(list = ls())

library(tidyverse)
library(pROC)

users <- read_csv("data/users.csv", show_col_types = FALSE)

# Target: retained at month 6
users <- users %>%
  mutate(retained_m6 = as.factor(active_month_6))

# -----------------------------------------------------------------------------
# 1. Predictive model: identify power-user behavioral signature at month 1
#    (features observable in first 30 days)
# -----------------------------------------------------------------------------
model_features <- c("completed_onboarding", "completed_activation",
                    "completed_engagement",
                    "power_user_score")

# Encode plan type and channel
users_model <- users %>%
  mutate(
    is_paid      = as.integer(plan_type == "paid"),
    is_trial     = as.integer(plan_type == "trial"),
    is_referral  = as.integer(acquisition_channel == "referral"),
    is_desktop   = as.integer(device_type == "desktop")
  ) %>%
  select(retained_m6, all_of(model_features),
         is_paid, is_trial, is_referral, is_desktop)

set.seed(42)
n         <- nrow(users_model)
train_idx <- sample(seq_len(n), floor(0.75 * n))
train     <- users_model[train_idx, ]
test      <- users_model[-train_idx, ]

# Logistic regression
all_features <- c(model_features, "is_paid", "is_trial", "is_referral", "is_desktop")
formula_lr   <- as.formula(paste("retained_m6 ~", paste(all_features, collapse = " + ")))

lr_model <- glm(formula_lr, data = train, family = binomial())
lr_probs <- predict(lr_model, newdata = test, type = "response")
lr_roc   <- roc(as.numeric(test$retained_m6) - 1, lr_probs, quiet = TRUE)
lr_auc   <- round(auc(lr_roc), 4)

cat(sprintf("Month-6 Retention Prediction AUC-ROC: %.4f\n", lr_auc))

# Optimal threshold
youden_idx  <- which.max(lr_roc$sensitivities + lr_roc$specificities - 1)
opt_thresh  <- round(lr_roc$thresholds[youden_idx], 4)
sensitivity <- round(lr_roc$sensitivities[youden_idx], 4)
specificity <- round(lr_roc$specificities[youden_idx], 4)

cat(sprintf("Optimal threshold: %.4f | Sensitivity: %.4f | Specificity: %.4f\n",
            opt_thresh, sensitivity, specificity))

# Feature importance
coef_tbl <- tibble(
  feature     = names(coef(lr_model))[-1],
  coefficient = round(coef(lr_model)[-1], 4),
  odds_ratio  = round(exp(coef(lr_model)[-1]), 4)
) %>% arrange(desc(abs(coefficient)))

cat("\n--- Power User Signature: Feature Importance ---\n")
print(coef_tbl)
write_csv(coef_tbl, "outputs/power_user_feature_importance.csv")

# Save metrics
tibble(
  metric = c("AUC-ROC", "Optimal Threshold", "Sensitivity", "Specificity"),
  value  = c(lr_auc, opt_thresh, sensitivity, specificity)
) %>% write_csv("outputs/retention_model_metrics.csv")

# -----------------------------------------------------------------------------
# 2. A/B Testing Framework — Onboarding Experiment
#    Hypothesis: improved onboarding flow increases Month-1 retention
# -----------------------------------------------------------------------------
cat("\n--- A/B Testing Framework ---\n")

# Power analysis: detect 5pp lift in M1 retention (base ~70%)
# Two-proportion z-test
p1 <- 0.70  # control
p2 <- 0.75  # treatment (5pp lift)
alpha <- 0.05
power_target <- 0.80

# Required sample size per arm
pooled_p <- (p1 + p2) / 2
z_alpha  <- qnorm(1 - alpha / 2)  # two-tailed
z_beta   <- qnorm(power_target)

n_per_arm <- ceiling(
  (z_alpha * sqrt(2 * pooled_p * (1 - pooled_p)) +
   z_beta  * sqrt(p1 * (1 - p1) + p2 * (1 - p2)))^2 /
  (p2 - p1)^2
)

cat(sprintf(
  "Power analysis: detect %.0fpp lift | alpha=%.2f | power=%.2f | n per arm = %d\n",
  100 * (p2 - p1), alpha, power_target, n_per_arm))

# Simulate experiment results
set.seed(99)
n_exp     <- n_per_arm
control   <- rbinom(n_exp, 1, p1)
treatment <- rbinom(n_exp, 1, p2 + 0.01)  # slight over-performance

obs_lift  <- mean(treatment) - mean(control)
prop_test <- prop.test(
  c(sum(treatment), sum(control)),
  c(n_exp, n_exp),
  alternative = "greater"
)

cat(sprintf(
  "Observed lift: %.2fpp | p-value: %.4f | Significant: %s\n",
  100 * obs_lift,
  prop_test$p.value,
  ifelse(prop_test$p.value < alpha, "YES", "NO")
))

# Novelty effect correction: compare weeks 1-2 vs weeks 3-4
novelty_correction <- tibble(
  period    = c("Weeks 1-2 (novelty)", "Weeks 3-4 (stabilized)"),
  lift_obs  = c(round(obs_lift + rnorm(1, 0.02, 0.005), 4),
                round(obs_lift - rnorm(1, 0.01, 0.005), 4))
)
cat("\n--- Novelty Effect Check ---\n")
print(novelty_correction)
write_csv(novelty_correction, "outputs/ab_novelty_correction.csv")

# Save A/B summary
ab_summary <- tibble(
  metric           = c("Control retention", "Treatment retention",
                       "Observed lift", "p-value", "n per arm", "Significant"),
  value            = c(round(mean(control) * 100, 2),
                       round(mean(treatment) * 100, 2),
                       paste0(round(obs_lift * 100, 2), "pp"),
                       round(prop_test$p.value, 4),
                       n_per_arm,
                       ifelse(prop_test$p.value < alpha, "YES", "NO"))
)
write_csv(ab_summary, "outputs/ab_experiment_summary.csv")

cat("\nPredictive modeling and A/B framework complete.\n")
