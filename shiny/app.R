# RetentionAnalytics: report-snapshot dashboard
# All displayed figures are transcribed from the November 9, 2026 report.
# This dashboard intentionally does not source the legacy outputs, which
# conflict with the report snapshot. It is a static presentation, not a rerun.

library(shiny)
library(bslib)
library(DT)

funnel <- data.frame(
  Stage = c("Signup", "Onboarding", "Activation", "Engagement", "Conversion"),
  Users = c(5000, 3874, 2407, 1387, 647),
  Share_of_signups = c(100, 77.48, 48.14, 27.74, 12.94)
)
model <- data.frame(
  Metric = c("ROC-AUC", "Precision", "Recall", "Specificity", "Accuracy", "Threshold"),
  Value = c("0.567", "0.406", "0.329", "0.781", "0.639", "0.346")
)
experiment <- data.frame(
  Period = c("Weeks 1-2", "Weeks 3-4"),
  Treatment_control_difference_pp = c(5.116, 1.199),
  One_sided_p_value = c("<0.001", "0.143")
)

ui <- page_navbar(
  title = "RetentionAnalytics | Report Snapshot",
  theme = bs_theme(bootswatch = "flatly"),
  header = div(
    class = "container-fluid",
    p(class = "text-muted",
      "Synthetic data. Figures transcribed from the November 9, 2026 report. Not a live pipeline refresh."),
    p(class = "small",
      "The report snapshot differs from historical saved outputs. See the repository README for provenance and reproducibility limits.")
  ),
  nav_panel("Funnel",
    layout_columns(
      value_box("Users", "5,000", theme = "primary"),
      value_box("Conversion", "12.94%", theme = "success"),
      value_box("Month-6 retention", "31.26%", theme = "info")
    ),
    card(card_header("Reported funnel"), DTOutput("funnel"))
  ),
  nav_panel("Retention model",
    card(card_header("Logistic-regression test metrics"), DTOutput("model")),
    p("ROC-AUC 0.567 indicates modest-to-weak discrimination. Treat this as a baseline, not a production-ready predictor.")
  ),
  nav_panel("Simulated experiment",
    card(card_header("Separate simulated A/B exercise"), DTOutput("experiment")),
    p("The experiment uses assumed outcome probabilities and 1,251 simulated users per arm. It is not a real product experiment or observed causal effect.")
  ),
  nav_panel("Provenance",
    card(
      card_header("Interpretation and limitations"),
      p("All data are synthetic."),
      p("The November 9 report values do not fully reconcile with historical saved outputs."),
      p("The corrected branch does not yet contain a complete end-to-end pipeline that regenerates every report figure."),
      p("This dashboard displays the report snapshot and does not execute the analysis scripts.")
    )
  )
)

server <- function(input, output, session) {
  output$funnel <- renderDT(datatable(funnel, rownames = FALSE,
    options = list(dom = "t", paging = FALSE)))
  output$model <- renderDT(datatable(model, rownames = FALSE,
    options = list(dom = "t", paging = FALSE)))
  output$experiment <- renderDT(datatable(experiment, rownames = FALSE,
    options = list(dom = "t", paging = FALSE)))
}

shinyApp(ui, server)
