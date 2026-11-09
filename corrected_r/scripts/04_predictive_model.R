# Leakage-aware M6 retention model and explicitly simulated A/B experiment.
rm(list = ls())
suppressPackageStartupMessages({
  library(tidyverse)
  library(pROC)
})
users <- read_csv("corrected_r/data/users.csv", show_col_types = FALSE)
dir.create("corrected_r/outputs", recursive = TRUE, showWarnings = FALSE)

# Predict M6 retention from first-month observable features only.
model_data <- users |>
  mutate(
    retained_m6 = as.integer(active_month_6),
    is_paid = as.integer(plan_type == "paid"),
    is_trial = as.integer(plan_type == "trial"),
    is_referral = as.integer(acquisition_channel == "referral"),
    is_desktop = as.integer(device_type == "desktop")
  ) |>
  select(user_id, retained_m6, completed_onboarding, completed_activation,
         completed_engagement, is_paid, is_trial, is_referral, is_desktop)

set.seed(2026)
stratified_split <- function(y, p) {
  idx <- unlist(lapply(split(seq_along(y), y), function(z) {
    sample(z, floor(length(z) * p))
  }), use.names = FALSE)
  sort(idx)
}
train_idx <- stratified_split(model_data$retained_m6, .60)
remaining <- setdiff(seq_len(nrow(model_data)), train_idx)
val_local <- stratified_split(model_data$retained_m6[remaining], .50)
val_idx <- remaining[val_local]
test_idx <- setdiff(remaining, val_idx)
train <- model_data[train_idx, ]
valid <- model_data[val_idx, ]
test <- model_data[test_idx, ]

features <- c("completed_onboarding", "completed_activation",
              "completed_engagement", "is_paid", "is_trial",
              "is_referral", "is_desktop")
fit <- glm(reformulate(features, response = "retained_m6"),
           data = train, family = binomial())
valid_prob <- predict(fit, newdata = valid, type = "response")
test_prob <- predict(fit, newdata = test, type = "response")
roc_valid <- pROC::roc(valid$retained_m6, valid_prob, quiet = TRUE, direction = "<")
threshold <- as.numeric(pROC::coords(
  roc_valid, x = "best", best.method = "youden",
  ret = "threshold", transpose = FALSE
)[1])
roc_test <- pROC::roc(test$retained_m6, test_prob, quiet = TRUE, direction = "<")
pred <- as.integer(test_prob >= threshold)
tp <- sum(pred == 1 & test$retained_m6 == 1)
fp <- sum(pred == 1 & test$retained_m6 == 0)
fn <- sum(pred == 0 & test$retained_m6 == 1)
tn <- sum(pred == 0 & test$retained_m6 == 0)
metrics <- tibble(
  metric = c("ROC-AUC", "Validation-selected threshold", "Precision",
             "Recall", "Specificity", "Accuracy", "Test observations"),
  value = c(as.numeric(pROC::auc(roc_test)), threshold,
            ifelse(tp + fp > 0, tp/(tp+fp), NA),
            tp/(tp+fn), tn/(tn+fp), (tp+tn)/length(pred), length(pred))
)
write_csv(metrics, "corrected_r/outputs/retention_model_metrics.csv")
write_csv(tibble(user_id = test$user_id, actual_m6 = test$retained_m6,
                 predicted_probability = test_prob, predicted_m6 = pred),
          "corrected_r/outputs/retention_test_predictions.csv")
coef_tbl <- tibble(
  feature = names(coef(fit))[-1],
  coefficient = unname(coef(fit)[-1]),
  odds_ratio = exp(coef(fit)[-1])
) |>
  arrange(desc(abs(coefficient)))
write_csv(coef_tbl, "corrected_r/outputs/power_user_feature_importance.csv")

# Independent synthetic randomized experiment. It is not a result from the
# 5,000-user observational simulation and is labelled as simulated throughout.
set.seed(99)
n_per_arm <- 1251L
experiment <- tibble(
  user_id = paste0("EXP", seq_len(2L * n_per_arm)),
  arm = rep(c("Control", "Treatment"), each = n_per_arm)
) |>
  mutate(
    # Weekly retention probabilities include a deliberately decaying novelty
    # effect in treatment. Week 1-2 and week 3-4 are actual simulated outcomes.
    week1_p = if_else(arm == "Treatment", .77, .70),
    week2_p = if_else(arm == "Treatment", .76, .70),
    week3_p = if_else(arm == "Treatment", .72, .70),
    week4_p = if_else(arm == "Treatment", .71, .70),
    week1 = rbinom(n(), 1, week1_p),
    week2 = rbinom(n(), 1, week2_p),
    week3 = rbinom(n(), 1, week3_p),
    week4 = rbinom(n(), 1, week4_p),
    early_retained = as.integer(week1 == 1 | week2 == 1),
    late_retained = as.integer(week3 == 1 | week4 == 1)
  )
exp_summary <- experiment |>
  group_by(arm) |>
  summarise(n = n(),
            early_retention_pct = 100 * mean(early_retained),
            late_retention_pct = 100 * mean(late_retained),
            week1_pct = 100 * mean(week1),
            week2_pct = 100 * mean(week2),
            week3_pct = 100 * mean(week3),
            week4_pct = 100 * mean(week4), .groups = "drop")
write_csv(exp_summary, "corrected_r/outputs/ab_experiment_summary.csv")

early_test <- prop.test(
  c(sum(experiment$early_retained[experiment$arm == "Treatment"]),
    sum(experiment$early_retained[experiment$arm == "Control"])),
  c(n_per_arm, n_per_arm), alternative = "greater", correct = FALSE
)
late_test <- prop.test(
  c(sum(experiment$late_retained[experiment$arm == "Treatment"]),
    sum(experiment$late_retained[experiment$arm == "Control"])),
  c(n_per_arm, n_per_arm), alternative = "greater", correct = FALSE
)
ab_tests <- tibble(
  period = c("Weeks 1-2", "Weeks 3-4"),
  treatment_minus_control_pp = c(
    100 * (mean(experiment$early_retained[experiment$arm == "Treatment"]) -
           mean(experiment$early_retained[experiment$arm == "Control"])),
    100 * (mean(experiment$late_retained[experiment$arm == "Treatment"]) -
           mean(experiment$late_retained[experiment$arm == "Control"]))
  ),
  p_value_one_sided = c(early_test$p.value, late_test$p.value),
  n_per_arm = n_per_arm
)
write_csv(ab_tests, "corrected_r/outputs/ab_period_tests.csv")
write_csv(tibble(
  assumption = c("Design", "Sample size per arm", "Control weekly retention probability",
                 "Treatment weekly probabilities", "Interpretation"),
  value = c("Independent simulated randomized experiment", as.character(n_per_arm),
            "0.70", "0.77, 0.76, 0.72, 0.71",
            "Synthetic illustration only. Not observed customer or product data.")
), "corrected_r/outputs/ab_assumptions.csv")
cat(sprintf("M6 model test ROC-AUC: %.3f | validation threshold: %.3f\n",
            as.numeric(pROC::auc(roc_test)), threshold))
cat("Corrected predictive model and simulated experiment complete.\n")
