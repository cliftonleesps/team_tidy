# Tibble operations
library(tidyverse)

# Connection to a DB
library(DBI)

source("../teamtidy_set_env.R")
source("insert_esmi.R")

db_connection <- dbConnect(RMariaDB::MariaDB(),
                           host=Sys.getenv("TEAMTIDY_DB_HOST"),
                           user = Sys.getenv("TEAMTIDY_DB_USER"),
                           password = Sys.getenv("TEAMTIDY_DB_PASS"),
                           dbname = 'data_science_jobs')


test_read <- read_csv("indeed/cali_oregon_utah_nj_emsi.csv")

insert_esmi_data(test_read, db_connection)

dbDisconnect(db_connection)


