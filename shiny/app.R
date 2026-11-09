# Corrected RetentionAnalytics dashboard
suppressPackageStartupMessages({
  library(shiny); library(bslib); library(tidyverse); library(scales)
})
root <- if (dir.exists("corrected_r/outputs")) "corrected_r/outputs" else if (dir.exists(file.path("..", "corrected_r", "outputs"))) file.path("..", "corrected_r", "outputs") else stop("Cannot find corrected_r/outputs. Run the corrected scripts from the repository root first.")
read_out <- function(file) read_csv(file.path(root, file), show_col_types = FALSE)
d <- list(
  funnel = read_out("funnel_overall.csv"),
  plan = read_out("funnel_by_plan.csv"),
  channel = read_out("funnel_by_channel.csv"),
  drop = read_out("funnel_dropoffs.csv"),
  ret = read_out("retention_curve_overall.csv"),
  ret_plan = read_out("retention_by_plan.csv"),
  ret_power = read_out("retention_by_power.csv"),
  m6 = read_out("m6_retention_by_cohort.csv"),
  dau = read_out("daily_active_users.csv"),
  dau_mau = read_out("dau_mau_summary.csv"),
  engagement = read_out("engagement_trend.csv"),
  model = read_out("retention_model_metrics.csv"),
  importance = read_out("power_user_feature_importance.csv"),
  ab = read_out("ab_experiment_summary.csv"),
  ab_tests = read_out("ab_period_tests.csv"),
  ab_assumptions = read_out("ab_assumptions.csv"),
  projection = read_out("funnel_improvement_projection.csv")
)
theme <- bs_theme(bootswatch = "flatly", primary = "#24364b")
ui <- page_navbar(
  title = "RetentionAnalytics | Product Analytics",
  theme = theme,
  header = tags$div(class="container-fluid text-muted py-2",
    "Corrected R pipeline | Synthetic data | Predictive metrics evaluated on held-out test data"),
  nav_panel("Executive Overview",
    layout_columns(
      value_box("Users", comma(5000), showcase = bsicons::bs_icon("people-fill")),
      value_box("Signup-to-conversion", paste0(round(d$funnel$pct_of_signups[d$funnel$step == "Conversion"],1),"%"),
                showcase = bsicons::bs_icon("funnel")),
      value_box("Month-6 retention", paste0(round(d$ret$retention_rate_pct[d$ret$months_since_signup == 6],1),"%"),
                showcase = bsicons::bs_icon("arrow-repeat")),
      value_box("Model ROC-AUC", round(as.numeric(d$model$value[d$model$metric=="ROC-AUC"]),3),
                showcase = bsicons::bs_icon("graph-up"))
    ),
    layout_columns(
      card(card_header("Conversion funnel"), plotOutput("funnel_overview",height=300)),
      card(card_header("Retention curve"), plotOutput("retention",height=300))
    ),
    card(card_header("Interpretation and scope"),
      p("All records are synthetic. Funnel scenarios are mechanical projections, not causal estimates. The A/B experiment is separately simulated and is not a live product experiment."))
  ),
  nav_panel("Funnel Analysis",
    navset_card_tab(
      nav_panel("Funnel Performance",
        layout_columns(
          card(card_header("Overall funnel"), plotOutput("funnel_detail",height=330)),
          card(card_header("Conversion by acquisition channel"), plotOutput("channel",height=330))
        ),
        card(card_header("Funnel by plan"), tableOutput("plan"))
      ),
      nav_panel("Drop-off & Scenarios",
        card(card_header("Drop-off ranking"), tableOutput("drop")),
        card(card_header("Illustrative activation scenario"), tableOutput("projection")),
        p(class="text-muted","The activation scenario is a mechanical projection that holds downstream conditional conversion rates constant. It is not a causal estimate.")
      )
    )
  ),
  nav_panel("Retention & Engagement",
    navset_card_tab(
      nav_panel("Retention & Cohorts",
        layout_columns(
          card(card_header("Retention by plan"), plotOutput("retplan",height=320)),
          card(card_header("Power vs regular users"), plotOutput("retpower",height=320))
        ),
        card(card_header("Month-6 retention by signup cohort"),
          p(class="text-muted","Each bar represents one monthly signup cohort. Labels show month-6 retention and cohort size."),
          plotOutput("m6",height=380))
      ),
      nav_panel("Product Engagement",
        layout_columns(
          card(card_header("DAU / MAU summary"), tableOutput("stickiness")),
          card(card_header("Session engagement"), tableOutput("engagement"))
        ),
        card(card_header("Daily active users"), plotOutput("dau",height=300))
      )
    )
  ),
  nav_panel("Predictive Model",
    navset_card_tab(
      nav_panel("Model Performance",
        layout_columns(
          card(card_header("Held-out test performance"), tableOutput("model")),
          card(card_header("How to read the results"),
            h5("Weak baseline discrimination"),
            p("The test ROC-AUC is 0.567. This indicates limited ability to rank users by future retention in this synthetic dataset."),
            p("Precision and recall describe performance at the classification threshold selected using validation data. Accuracy should be interpreted cautiously because it can be misleading when outcome classes are imbalanced.")
          )
        ),
        p(class="text-muted","The model uses first-month features. The classification threshold is selected on validation data and evaluated once on the untouched test set.")
      ),
      nav_panel("Feature Associations & Interpretation",
        card(card_header("Logistic regression coefficients"),
          p(class="text-muted","Positive coefficients are associated with higher modeled log-odds of retention; negative coefficients are associated with lower modeled log-odds. These are associations, not causal effects."),
          plotOutput("importance",height=420)
        ),
        p(class="text-muted","Coefficient magnitudes are shown on the model's log-odds scale. They should not be interpreted as percentage-point changes in retention.")
      )
    )
  ),
  nav_panel("Experimentation",
    card(card_header("Simulated randomized experiment"), tableOutput("ab")),
    card(card_header("Early vs. later period tests"), tableOutput("abtests")),
    card(card_header("Experiment assumptions"), tableOutput("abassumptions")),
    p(class="text-muted","This is an independent synthetic experiment, not an experiment conducted on observed users. Week-specific retention probabilities are stipulated simulation inputs. The early-to-late comparison illustrates a designed decay pattern, not an empirical novelty-effect finding.")
  )
)
server <- function(input, output, session) {
  funnel_plot <- function() {
    ggplot(d$funnel, aes(step, pct_of_signups)) +
      geom_col(fill="#2878a5", width=.72) +
      geom_text(aes(label=paste0(round(pct_of_signups,1),"%")), vjust=-.4, size=3.5) +
      scale_y_continuous(limits=c(0,105), breaks=seq(0,100,25), labels=label_number(suffix="%")) +
      labs(x=NULL,y="Share of signups") + theme_minimal()
  }
  output$funnel_overview <- renderPlot(funnel_plot())
  output$funnel_detail <- renderPlot(funnel_plot())
  output$channel <- renderPlot({
    ggplot(d$channel,aes(reorder(acquisition_channel,conversion_pct),conversion_pct))+
      geom_col(fill="#27936f")+coord_flip()+labs(x=NULL,y="Conversion (%)")+theme_minimal()
  })
  output$plan <- renderTable(d$plan |>
    rename(Plan = plan_type, Users = n_users,
           `Onboarding (%)` = completed_onboarding_pct,
           `Activation (%)` = completed_activation_pct,
           `Engagement (%)` = completed_engagement_pct,
           `Conversion (%)` = completed_conversion_pct), digits=1)
  output$drop <- renderTable(d$drop |>
    rename(Step = step, Users = users, `Share of signups (%)` = pct_of_signups,
           `Step conversion (%)` = step_conversion_pct,
           `Step drop-off (%)` = step_dropoff_pct), digits=1)
  output$projection <- renderTable(d$projection |>
    rename(Scenario = scenario, `Activation rate (%)` = activation_rate_pct,
           `Projected conversions` = projected_conversions,
           `Relative lift (%)` = relative_conversion_lift_pct), digits=1)
  output$retention <- renderPlot({
    ggplot(d$ret,aes(months_since_signup,retention_rate_pct))+
      geom_line(linewidth=1.1,color="#2878a5")+geom_point()+
      scale_y_continuous(limits=c(0,100), breaks=seq(0,100,20))+
      labs(x="Months since signup",y="Retained users (%)")+theme_minimal()
  })
  output$retplan <- renderPlot({
    ggplot(d$ret_plan,aes(months_since_signup,retention_rate_pct,color=plan_type))+
      geom_line(linewidth=1)+geom_point()+
      scale_y_continuous(limits=c(0,100), breaks=seq(0,100,20))+
      labs(x="Months since signup",y="Retention (%)",color="Plan")+
      theme_minimal()
  })
  output$retpower <- renderPlot({
    ggplot(d$ret_power,aes(months_since_signup,retention_rate_pct,color=segment))+
      geom_line(linewidth=1)+geom_point()+
      scale_y_continuous(limits=c(0,100), breaks=seq(0,100,20))+
      labs(x="Months since signup",y="Retention (%)",color=NULL)+
      theme_minimal()
  })
  output$m6 <- renderPlot({
    cohort_plot <- d$m6 |>
      mutate(
        cohort_date = as.Date(cohort_month),
        cohort_label = format(cohort_date, "%b %Y"),
        cohort_label = factor(cohort_label, levels = unique(cohort_label))
      )
    ggplot(cohort_plot,aes(cohort_label,m6_retention_pct))+
      geom_col(fill="#8064a2",width=.72)+
      geom_text(aes(label=paste0(round(m6_retention_pct,1),"%\nn=",cohort_size)),
                vjust=-.25,size=3)+
      scale_y_continuous(limits=c(0,100),breaks=seq(0,100,20),
                         labels=label_number(suffix="%"),
                         expand=expansion(mult=c(0,.12)))+
      scale_x_discrete(breaks=levels(cohort_plot$cohort_label)[seq(1,nlevels(cohort_plot$cohort_label),by=2)]) +
      labs(x="Signup cohort",y="Month-6 retention (%)")+
      theme_minimal()+
      theme(axis.text.x=element_text(angle=35,hjust=1))
  })
  output$stickiness <- renderTable(d$dau_mau |>
    mutate(MAU = format(round(mau), big.mark=",", scientific=FALSE, trim=TRUE),
           Days = format(round(calendar_days), big.mark=",", scientific=FALSE, trim=TRUE)) |>
    select(Month = year_month, `Average DAU` = avg_dau, MAU,
           `DAU/MAU (%)` = avg_dau_mau_pct, Days), digits=2)
  output$engagement <- renderTable(d$engagement |>
    mutate(Sessions = format(round(sessions), big.mark=",", scientific=FALSE, trim=TRUE),
           `Active users` = format(round(unique_active_users), big.mark=",", scientific=FALSE, trim=TRUE)) |>
    select(Month = year_month, Sessions,
           `Avg. session (min)` = avg_session_length_min,
           `Actions/session` = avg_actions_per_session, `Active users`), digits=2)
  output$dau <- renderPlot({
    ggplot(d$dau,aes(session_date,dau))+geom_line(color="#2878a5")+
      labs(x="Date",y="Daily active users")+theme_minimal()
  })
  output$model <- renderTable({
    d$model |>
      mutate(value = case_when(
        metric == "ROC-AUC" ~ sprintf("%.3f", as.numeric(value)),
        metric == "Validation-selected threshold" ~ sprintf("%.3f", as.numeric(value)),
        metric == "Test observations" ~ comma(as.numeric(value), accuracy=1),
        TRUE ~ paste0(sprintf("%.1f", as.numeric(value) * 100), "%")
      )) |>
      rename(Metric = metric, Result = value)
  }, striped=TRUE, bordered=FALSE, spacing="s")
  output$importance <- renderPlot({
    feature_labels <- c(
      is_paid = "Paid plan indicator",
      completed_engagement = "Completed engagement",
      is_trial = "Trial plan indicator",
      is_desktop = "Desktop indicator",
      is_referral = "Referral indicator",
      completed_activation = "Completed activation",
      completed_onboarding = "Completed onboarding"
    )
    importance_plot <- d$importance |>
      mutate(feature_label = recode(feature, !!!as.list(feature_labels), .default=feature))
    ggplot(importance_plot,aes(reorder(feature_label,coefficient),coefficient))+
      geom_hline(yintercept=0,color="grey55",linewidth=.5)+
      geom_col(fill="#8064a2",width=.7)+coord_flip()+
      labs(x=NULL,y="Coefficient (log-odds scale)")+
      theme_minimal()+
      theme(panel.grid.minor=element_blank())
  })
  output$ab <- renderTable({
    d$ab |>
      mutate(across(any_of(c("early_retention_pct", "late_retention_pct",
                             "week1_pct", "week2_pct", "week3_pct", "week4_pct")),
                    ~ paste0(sprintf("%.1f", as.numeric(.x)), "%")),
             n = comma(as.numeric(n), accuracy=1)) |>
      rename(Arm = arm, `Sample size` = n,
             `Early retention` = early_retention_pct,
             `Late retention` = late_retention_pct,
             `Week 1` = week1_pct, `Week 2` = week2_pct,
             `Week 3` = week3_pct, `Week 4` = week4_pct)
  }, striped=TRUE, bordered=FALSE, spacing="s")
  output$abtests <- renderTable({
    d$ab_tests |>
      mutate(
        treatment_minus_control_pp = sprintf("%.2f", treatment_minus_control_pp),
        p_value_one_sided = if_else(p_value_one_sided < 0.001, "<0.001",
                                    formatC(p_value_one_sided, format="f", digits=3)),
        n_per_arm = comma(as.numeric(n_per_arm), accuracy=1)
      ) |>
      rename(Period = period, `Treatment effect (percentage points)` = treatment_minus_control_pp,
             `One-sided p-value` = p_value_one_sided,
             `Sample size per arm` = n_per_arm)
  }, striped=TRUE, bordered=FALSE, spacing="s")
  output$abassumptions <- renderTable({
    d$ab_assumptions |>
      rename(Assumption = assumption, `Specified value` = value)
  }, striped=TRUE, bordered=FALSE, spacing="s")
}
shinyApp(ui,server)
