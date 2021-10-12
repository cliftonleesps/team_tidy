# Tibble operations
library(tidyverse)

# For data cleanup
library(stringr)

# Creating tables
library(dbplyr)

# Connection to a DB
library(RJDBC)

source("../teamtidy_set_env.R")

db_connection <- dbConnect(RMariaDB::MariaDB(), 
                           host=Sys.getenv("TEAMTIDY_DB_HOST"), 
                           user = Sys.getenv("TEAMTIDY_DB_USER"), 
                           password = Sys.getenv("TEAMTIDY_DB_PASS"), 
                           dbname = 'data_science_jobs')


rs <- dbSendQuery(db_connection, "select job_id, title, substring(description, 1, 100) as job_description from job")
dbFetch(rs)

