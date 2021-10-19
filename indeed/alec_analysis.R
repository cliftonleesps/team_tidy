# Tibble operations

install.packages("ggpubr")

library(ggpubr)
library(tidyverse)

# Connection to a DB
library(DBI)

setwd("/Users/alecmccabe/Desktop/Masters Program/DATA 607/project_3_git/team_tidy/indeed")

source("../../teamtidy_set_env.R")
source("../scripts/insert_esmi.R")

db_connection <- dbConnect(RMariaDB::MariaDB(),
                           host=Sys.getenv("TEAMTIDY_DB_HOST"),
                           user = Sys.getenv("TEAMTIDY_DB_USER"),
                           password = Sys.getenv("TEAMTIDY_DB_PASS"),
                           dbname = 'data_science_jobs')

get_data_query <- "select j.*, s.description, s.type from job j join skill s on j.job_id = s.job_id"

get_jobs <- "select * from job"

data <- dbGetQuery(db_connection,get_data_query)

job_data <- dbGetQuery(db_connection,get_jobs)


# analysis of state distribution

unique(job_data$state)

NY <- c("New-York","New York, NY")
OR <- c("Oregon")
CA <- c("California", "California, United States", "Los Angeles Metropolitan ")
NJ <- c("New-Jersey")
TX <- c("Texas")
UT <- c("Utah")
TN <- c("Tennessee, United States")

job_data_normal <- job_data %>%
  mutate(
    states_collapsed = fct_collapse(state,
                                   NY = NY,
                                   OR = OR,
                                   CA = CA,
                                   NJ = NJ,
                                   TX = TX,
                                   UT = UT,
                                   TN = TN)
  )

unique(job_data_normal$states_collapsed)

library(stringr)

extract_state <- function(state_string){
  str_extract(state_string, "[A-Z]{2}")
}


job_data_normal <- job_data_normal %>%
  mutate(
    state_id = unlist(lapply(job_data_normal$states_collapsed,extract_state))
  )

job_data_normal %>%
  ggplot() + 
  geom_bar(aes(x=reorder(state_id,state_id,function(x)-length(x)))) +
  labs(x = "State Id")


# Analysis of skills section

skill_counts <- data %>%
  group_by(job_id) %>%
  count(type)

skill_counts <- ungroup(skill_counts)


get_proportion <- function(id){
  filtered <- skill_counts %>%
                filter(job_id == id)
  
  total <- sum(filtered$n)
  
  hard <- filtered %>%
            filter(type == "Hard Skill") %>%
            select(n) %>%
            .$n
  
  return(hard/total)
}

job_ids <- unique(data$job_id)

job_proportions <- job_ids %>%
  lapply(get_proportion)

job_proportions <- unlist(job_proportions)



jobs_df <- as_tibble(job_ids)
colnames(jobs_df) <- c("job_id")

jobs_df <- jobs_df %>%
              mutate(
                hard_proportion = job_proportions
              )

final_jobs <- bind_cols(job_data, jobs_df)

final_jobs$hard_proportion

final_jobs %>%
  ggplot() + 
  geom_boxplot(aes(x=hard_proportion, y=original_source))


so_props <- final_jobs %>%
  filter(
    original_source == "stack overflow"
  ) %>%
  select(hard_proportion) %>%
  .$hard_proportion

other_props <- final_jobs %>%
  filter(
    original_source != "stack overflow"
  ) %>%
  select(hard_proportion) %>%
  .$hard_proportion


res <- t.test(so_props, other_props, var.equal = TRUE)
res


