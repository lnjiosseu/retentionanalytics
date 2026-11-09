# Synthetic randomized experiment. This is a methodology demonstration, not a real product experiment.
library(tidyverse)
set.seed(2026); dir.create("corrected_r/outputs",recursive=TRUE,showWarnings=FALSE)
n <- 5000
e <- tibble(user_id=sprintf("EXP%05d",1:n),treatment=rbinom(n,1,.5),
 baseline_p=runif(n,.55,.80))|>
 mutate(week1=rbinom(n,1,pmin(.99,baseline_p+treatment*.06)),
        week2=rbinom(n,1,pmin(.99,baseline_p+treatment*.05)),
        week3=rbinom(n,1,pmin(.99,baseline_p+treatment*.03)),
        week4=rbinom(n,1,pmin(.99,baseline_p+treatment*.03)))
weekly <- e|>pivot_longer(starts_with("week"),names_to="week",values_to="retained")|>
 group_by(treatment,week)|>summarise(users=n(),retention=mean(retained),.groups="drop")
write_csv(weekly,"corrected_r/outputs/ab_weekly_retention.csv")
test <- prop.test(c(sum(e$week4[e$treatment==1]),sum(e$week4[e$treatment==0])),
 c(sum(e$treatment==1),sum(e$treatment==0)),alternative="two.sided",correct=FALSE)
result <- tibble(control_rate=mean(e$week4[e$treatment==0]),
 treatment_rate=mean(e$week4[e$treatment==1]),
 risk_difference=mean(e$week4[e$treatment==1])-mean(e$week4[e$treatment==0]),
 p_value=test$p.value,ci_low=test$conf.int[1],ci_high=test$conf.int[2],
 n_control=sum(e$treatment==0),n_treatment=sum(e$treatment==1))
write_csv(result,"corrected_r/outputs/ab_primary_result.csv")
