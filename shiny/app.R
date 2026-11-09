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
    layout_columns(
      card(card_header("Overall funnel"), plotOutput("funnel_detail",height=330)),
      card(card_header("Conversion by acquisition channel"), plotOutput("channel",height=330))
    ),
    card(card_header("Funnel by plan"), tableOutput("plan")),
    card(card_header("Drop-off ranking"), tableOutput("drop")),
    card(card_header("Illustrative activation scenario"), tableOutput("projection"))
  ),
  nav_panel("Retention & Engagement",
    layout_columns(
      card(card_header("Retention by plan"), plotOutput("retplan",height=320)),
      card(card_header("Power vs regular users"), plotOutput("retpower",height=320))
    ),
    card(card_header("Month-6 retention by signup cohort"),
      p(class="text-muted","Each bar represents one monthly signup cohort. Labels show month-6 retention and cohort size."),
      plotOutput("m6",height=340)),
    layout_columns(
      card(card_header("DAU / MAU summary"), tableOutput("stickiness")),
      card(card_header("Session engagement"), tableOutput("engagement"))
    ),
    card(card_header("Daily active users"), plotOutput("dau",height=280))
  ),
  nav_panel("Predictive Model",
    layout_columns(
      card(card_header("Model evaluation"), tableOutput("model")),
      card(card_header("Model coefficients"), plotOutput("importance",height=360))
    ),
    p(class="text-muted","Logistic regression uses first-month features. The classification threshold is selected on validation data and evaluated once on the held-out test set. Coefficients are associations, not causal effects. The test ROC-AUC is a weak baseline result and should not be interpreted as production-ready predictive performance.")
  ),
  nav_panel("Experimentation",
    card(card_header("Simulated randomized experiment"), tableOutput("ab")),
    card(card_header("Early vs later period tests"), tableOutput("abtests")),
    card(card_header("Experiment assumptions"), tableOutput("abassumptions")),
    p(class="text-muted","This is an independent synthetic experiment. Week-specific retention probabilities are stipulated simulation inputs. The early-to-late comparison illustrates a decaying treatment effect, not an empirical novelty-effect finding.")
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
  output$plan <- renderTable(d$plan, digits=1)
  output$drop <- renderTable(d$drop, digits=1)
  output$projection <- renderTable(d$projection, digits=1)
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
      mutate(cohort_month = as.Date(paste0(substr(as.character(cohort_month), 1, 7), "-01")) )
    ggplot(cohort_plot,aes(cohort_month,m6_retention_pct))+
      geom_col(fill="#8064a2",width=24)+
      geom_text(aes(label=paste0(round(m6_retention_pct,1),"%\nn=",cohort_size)),
                vjust=-.25,size=3)+
      scale_x_date(date_breaks="2 months",date_labels="%b %Y",
                   expand=expansion(mult=c(.02,.04)))+
      scale_y_continuous(limits=c(0,100),breaks=seq(0,100,20),
                         labels=label_number(suffix="%"))+
      labs(x="Signup cohort",y="Month-6 retention (%)")+
      theme_minimal()+
      theme(axis.text.x=element_text(angle=35,hjust=1))
  })
  output$stickiness <- renderTable(d$dau_mau,digits=1)
  output$engagement <- renderTable(d$engagement,digits=1)
  output$dau <- renderPlot({
    ggplot(d$dau,aes(session_date,dau))+geom_line(color="#2878a5")+
      labs(x="Date",y="Daily active users")+theme_minimal()
  })
  output$model <- renderTable(d$model,digits=3)
  output$importance <- renderPlot({
    ggplot(d$importance,aes(reorder(feature,coefficient),coefficient))+
      geom_col(fill="#8064a2")+coord_flip()+
      labs(x=NULL,y="Logistic regression coefficient")+theme_minimal()
  })
  output$ab <- renderTable(d$ab,digits=1)
  output$abtests <- renderTable(d$ab_tests,digits=3)
  output$abassumptions <- renderTable(d$ab_assumptions)
}
shinyApp(ui,server)
