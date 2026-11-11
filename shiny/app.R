# =============================================================================
# RetentionAnalytics: shiny/app.R — Product Analytics Dashboard
# =============================================================================

library(shiny)
library(bslib)
library(tidyverse)

# Historical dashboard: reads original main-branch outputs only. It does not display
# the later Nov. 9 PDF analysis or corrected_r outputs. See README.md.

load_data <- function() {
  list(
    users         = read_csv("../data/users.csv",                          show_col_types = FALSE),
    funnel        = read_csv("../outputs/funnel_overall.csv",              show_col_types = FALSE),
    funnel_plan   = read_csv("../outputs/funnel_by_plan.csv",              show_col_types = FALSE),
    funnel_ch     = read_csv("../outputs/funnel_by_channel.csv",           show_col_types = FALSE),
    ret_overall   = read_csv("../outputs/retention_curve_overall.csv",     show_col_types = FALSE),
    ret_plan      = read_csv("../outputs/retention_by_plan.csv",           show_col_types = FALSE),
    ret_power     = read_csv("../outputs/retention_by_power.csv",          show_col_types = FALSE),
    m6_cohort     = read_csv("../outputs/m6_retention_by_cohort.csv",      show_col_types = FALSE),
    dau_mau       = read_csv("../outputs/dau_mau_summary.csv",             show_col_types = FALSE),
    dau           = read_csv("../outputs/daily_active_users.csv",          show_col_types = FALSE),
    engagement    = read_csv("../outputs/engagement_trend.csv",            show_col_types = FALSE),
    feat_imp      = read_csv("../outputs/power_user_feature_importance.csv",show_col_types = FALSE),
    ret_metrics   = read_csv("../outputs/retention_model_metrics.csv",     show_col_types = FALSE),
    ab_summary    = read_csv("../outputs/ab_experiment_summary.csv",       show_col_types = FALSE),
    ab_novelty    = read_csv("../outputs/ab_novelty_correction.csv",       show_col_types = FALSE),
    dropoffs      = read_csv("../outputs/funnel_dropoffs.csv",             show_col_types = FALSE)
  )
}

d <- load_data()

PAL <- list(high = "#e74c3c", med = "#f39c12", low = "#27ae60",
            blue = "#2980b9", purple = "#8e44ad", dark = "#2c3e50")

ui <- page_navbar(
  title = "RetentionAnalytics | Historical Original Baseline Dashboard",
  theme = bs_theme(bootswatch = "flatly", primary = PAL$dark),

  # ── Tab 1: Funnel ──────────────────────────────────────────────────────────
  nav_panel("Conversion Funnel",
    layout_columns(
      col_widths = c(3, 3, 3, 3),
      value_box("Total Users",   scales::comma(nrow(d$users)),
                showcase = bsicons::bs_icon("people-fill"),  theme = "primary"),
      value_box("Activation Rate",
                paste0(d$funnel$pct_of_signup[d$funnel$step == "Activation"], "%"),
                showcase = bsicons::bs_icon("lightning-fill"), theme = "warning"),
      value_box("Conversion Rate",
                paste0(d$funnel$pct_of_signup[d$funnel$step == "Conversion"], "%"),
                showcase = bsicons::bs_icon("trophy-fill"), theme = "success"),
      value_box("Top Drop-off Step",
                d$dropoffs$step[1],
                showcase = bsicons::bs_icon("arrow-down-circle"), theme = "danger")
    ),
    layout_columns(
      col_widths = c(7, 5),
      card(
        card_header("Overall Conversion Funnel"),
        plotOutput("plot_funnel", height = "350px")
      ),
      card(
        card_header("Conversion by Acquisition Channel"),
        plotOutput("plot_channel", height = "350px")
      )
    ),
    card(
      card_header("Funnel by Plan Type"),
      tableOutput("tbl_funnel_plan")
    )
  ),

  # ── Tab 2: Retention ───────────────────────────────────────────────────────
  nav_panel("Retention Cohorts",
    layout_columns(
      col_widths = c(6, 6),
      card(
        card_header("Retention Curves — Plan Type"),
        plotOutput("plot_ret_plan", height = "320px")
      ),
      card(
        card_header("Power User vs Regular — Retention"),
        plotOutput("plot_ret_power", height = "320px")
      )
    ),
    card(
      card_header("Month-6 Retention by Signup Cohort"),
      plotOutput("plot_m6_cohort", height = "300px")
    )
  ),

  # ── Tab 3: DAU / MAU ──────────────────────────────────────────────────────
  nav_panel("DAU / MAU",
    layout_columns(
      col_widths = c(4, 4, 4),
      card(card_header("Monthly MAU"), tableOutput("tbl_mau")),
      card(card_header("Avg DAU/MAU Stickiness"), tableOutput("tbl_stickiness")),
      card(card_header("Engagement"), tableOutput("tbl_engagement"))
    ),
    card(
      card_header("Daily Active Users Trend"),
      plotOutput("plot_dau", height = "300px")
    )
  ),

  # ── Tab 4: Predictive Model & A/B ─────────────────────────────────────────
  nav_panel("Prediction & Experimentation",
    layout_columns(
      col_widths = c(6, 6),
      card(
        card_header("Power User Signature — Feature Importance"),
        plotOutput("plot_feat_imp", height = "360px"),
        hr(),
        card_header("Model Metrics"),
        tableOutput("tbl_ret_metrics")
      ),
      card(
        card_header("A/B Experiment: Onboarding Flow"),
        tableOutput("tbl_ab"),
        hr(),
        card_header("Novelty Effect Check"),
        tableOutput("tbl_novelty")
      )
    )
  )
)

server <- function(input, output, session) {

  output$plot_funnel <- renderPlot({
    d$funnel %>%
      mutate(step = fct_inorder(step)) %>%
      ggplot(aes(x = step, y = pct_of_signup)) +
      geom_col(fill = PAL$blue, alpha = 0.85) +
      geom_text(aes(label = paste0(pct_of_signup, "%")),
                vjust = -0.4, size = 4.5) +
      labs(x = NULL, y = "% of Signups") +
      theme_minimal(base_size = 13)
  })

  output$plot_channel <- renderPlot({
    d$funnel_ch %>%
      mutate(acquisition_channel = fct_reorder(acquisition_channel, pct_conversion)) %>%
      ggplot(aes(x = acquisition_channel, y = pct_conversion, fill = pct_conversion)) +
      geom_col() + coord_flip() +
      scale_fill_gradient(low = PAL$low, high = PAL$blue) +
      labs(x = NULL, y = "Conversion Rate (%)") +
      theme_minimal(base_size = 13) + theme(legend.position = "none")
  })

  output$tbl_funnel_plan <- renderTable({ d$funnel_plan }, striped = TRUE, hover = TRUE)

  output$plot_ret_plan <- renderPlot({
    d$ret_plan %>%
      ggplot(aes(x = months_since_signup, y = retention_rate,
                 color = plan_type, group = plan_type)) +
      geom_line(size = 1.2) + geom_point(size = 2) +
      scale_color_manual(values = c(free = PAL$blue, trial = PAL$med, paid = PAL$low)) +
      labs(x = "Months Since Signup", y = "Retention Rate (%)", color = "Plan") +
      theme_minimal(base_size = 13)
  })

  output$plot_ret_power <- renderPlot({
    d$ret_power %>%
      ggplot(aes(x = months_since_signup, y = retention_rate,
                 color = segment, group = segment)) +
      geom_line(size = 1.2) + geom_point(size = 2) +
      scale_color_manual(values = c("Power User" = PAL$purple, "Regular User" = PAL$blue)) +
      labs(x = "Months Since Signup", y = "Retention Rate (%)", color = NULL) +
      theme_minimal(base_size = 13)
  })

  output$plot_m6_cohort <- renderPlot({
    d$m6_cohort %>%
      mutate(cohort_month = format(as.Date(cohort_month), "%b %Y")) %>%
      ggplot(aes(x = cohort_month, y = m6_retention_rate)) +
      geom_col(fill = PAL$purple, alpha = 0.85) +
      geom_text(aes(label = paste0(m6_retention_rate, "%")), vjust = -0.3, size = 3.5) +
      labs(x = "Signup Cohort", y = "Month-6 Retention (%)") +
      theme_minimal(base_size = 12) +
      theme(axis.text.x = element_text(angle = 30, hjust = 1))
  })

  output$tbl_mau       <- renderTable({ d$dau_mau %>% select(year_month, mau) },
                                      striped = TRUE)
  output$tbl_stickiness <- renderTable({
    d$dau_mau %>% select(year_month, avg_dau, avg_stickiness)
  }, striped = TRUE)
  output$tbl_engagement <- renderTable({ d$engagement }, striped = TRUE)

  output$plot_dau <- renderPlot({
    d$dau %>%
      ggplot(aes(x = as.Date(session_date), y = dau)) +
      geom_line(color = PAL$blue, size = 0.8) +
      geom_smooth(method = "loess", se = FALSE, color = PAL$high, linetype = "dashed") +
      labs(x = "Date", y = "Daily Active Users") +
      theme_minimal(base_size = 13)
  })

  output$plot_feat_imp <- renderPlot({
    d$feat_imp %>%
      mutate(feature = fct_reorder(feature, abs(coefficient)),
             direction = ifelse(coefficient > 0, "Increases Retention", "Decreases Retention")) %>%
      ggplot(aes(x = feature, y = coefficient, fill = direction)) +
      geom_col() + coord_flip() +
      scale_fill_manual(values = c("Increases Retention" = PAL$low,
                                   "Decreases Retention" = PAL$high)) +
      labs(x = NULL, y = "Log-Odds Coefficient", fill = NULL) +
      theme_minimal(base_size = 13)
  })

  output$tbl_ret_metrics <- renderTable({ d$ret_metrics }, striped = TRUE)
  output$tbl_ab          <- renderTable({ d$ab_summary }, striped = TRUE)
  output$tbl_novelty     <- renderTable({ d$ab_novelty }, striped = TRUE)
}

shinyApp(ui, server)
