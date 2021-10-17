# This R script defines one function to take an ESMI dataframe and insert it into the job and skill tables
# This function assumes a database connection has already been opened

# Tibble operations
library(tidyverse)

# all_skills_df is a data frame of jobs and skills together
# db_connection is a regular DBI connection
insert_esmi_data <- function(all_skills_df, db_connection) {

  # initialize temporary variables
  job_id <- 0
  current_job_description <- ''
  
  # iterate through the ESMI data frame
  for (i in 1:nrow(all_skills_df)) {
    job <- all_skills_df[i,]
    
    # if we have a new description, we have a new job so insert a new job record
    if (current_job_description != job$description) {
      job_tibble <- tibble(
        job_title = job$job_title,
        company_name = job$company_name ,
        state = job$state,
        description = job$description
      )
      dbAppendTable(db_connection, "job", job_tibble)
      
      # update the job_id from the db
      query_result <- dbGetQuery(db_connection,"SELECT max(job_id) as job_id FROM job"  )
      job_id <- query_result$job_id
      # print (sprintf("max_id: %s", job_id))
      
      # update the temporary description variable
      current_job_description <- job$description
    }
    
    # now insert the skill into the skill table
    skill_tibble <- tibble(
      job_id = job_id,
      description = job$skill,
      type = job$type
    )
    dbAppendTable(db_connection, "skill", skill_tibble)
  }
  
}