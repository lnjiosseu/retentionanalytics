library(tidyverse)
dir.create("corrected_r/outputs",recursive=TRUE,showWarnings=FALSE)
u <- read_csv("data/users.csv",show_col_types=FALSE)
s <- read_csv("data/sessions.csv",show_col_types=FALSE)|>mutate(session_date=as.Date(session_date))
m6 <- u|>group_by(power_user)|>summarise(users=n(),retained_m6=sum(active_month_6==1),
 m6_retention=mean(active_month_6==1),.groups="drop")
write_csv(m6,"corrected_r/outputs/m6_by_power_segment.csv")
calendar <- tibble(session_date=seq(min(s$session_date),max(s$session_date),by="day"))
daily <- s|>distinct(session_date,user_id)|>count(session_date,name="dau")|>
 right_join(calendar,by="session_date")|>mutate(dau=replace_na(dau,0L))|>arrange(session_date)
write_csv(daily,"corrected_r/outputs/daily_dau_calendar.csv")
