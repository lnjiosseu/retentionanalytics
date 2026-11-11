# RetentionAnalytics corrected pipeline: chronological M6 retention prediction
# Predictors are baseline/user attributes and funnel events available before M6.
library(tidyverse)
library(pROC)
dir.create("corrected_r/outputs", recursive = TRUE, showWarnings = FALSE)
users <- read_csv("data/users.csv", show_col_types = FALSE) |>
  mutate(cohort_month = as.Date(cohort_month),
         retained_m6 = as.integer(active_month_6 == 1),
         is_paid = as.integer(plan_type == "paid"),
         is_trial = as.integer(plan_type == "trial"),
         is_referral = as.integer(acquisition_channel == "referral"),
         is_desktop = as.integer(device_type == "desktop"))
features <- c("completed_onboarding", "completed_activation",
              "completed_engagement", "is_paid", "is_trial",
              "is_referral", "is_desktop")
model_data <- users |>
  select(user_id, cohort_month, retained_m6, all_of(features)) |>
  drop_na()
train <- filter(model_data, cohort_month <= as.Date("2023-08-01"))
validation <- filter(model_data, cohort_month >= as.Date("2023-09-01"),
                     cohort_month <= as.Date("2023-10-01"))
test <- filter(model_data, cohort_month >= as.Date("2023-11-01"))
stopifnot(nrow(train) > 0, nrow(validation) > 0, nrow(test) > 0,
          n_distinct(train$retained_m6) == 2,
          n_distinct(validation$retained_m6) == 2,
          n_distinct(test$retained_m6) == 2)
fit <- glm(reformulate(features, response = "retained_m6"),
           data = train, family = binomial())
validation$prob <- predict(fit, newdata = validation, type = "response")
test$prob <- predict(fit, newdata = test, type = "response")
validation_roc <- roc(validation$retained_m6, validation$prob, quiet = TRUE)
best_idx <- which.max(validation_roc$sensitivities +
                      validation_roc$specificities - 1)
threshold <- as.numeric(validation_roc$thresholds[best_idx])
test$predicted <- as.integer(test$prob >= threshold)
test_roc <- roc(test$retained_m6, test$prob, quiet = TRUE)
tp <- sum(test$predicted == 1 & test$retained_m6 == 1)
fp <- sum(test$predicted == 1 & test$retained_m6 == 0)
tn <- sum(test$predicted == 0 & test$retained_m6 == 0)
fn <- sum(test$predicted == 0 & test$retained_m6 == 1)
metrics <- tibble(
  metric = c("ROC_AUC", "Validation_selected_threshold", "Precision",
             "Recall", "Specificity", "Accuracy", "Test_n"),
  value = c(as.numeric(auc(test_roc)), threshold,
            ifelse(tp + fp > 0, tp / (tp + fp), NA_real_),
            ifelse(tp + fn > 0, tp / (tp + fn), NA_real_),
            ifelse(tn + fp > 0, tn / (tn + fp), NA_real_),
            (tp + tn) / nrow(test), nrow(test))
)
write_csv(metrics, "corrected_r/outputs/retention_model_metrics.csv")
write_csv(tibble(user_id = test$user_id, actual = test$retained_m6,
                 probability = test$prob, predicted = test$predicted),
          "corrected_r/outputs/retention_test_predictions.csv")
