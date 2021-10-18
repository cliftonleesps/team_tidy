library(httr)
library(jsonlite)
library(tidyverse)
library(stringr)

client_id_7 <- "b4gabbxyfmnp0bus"
secret_7 <- "QQODWzzv"
scope_7 <- "emsi_open"


client_id_6 <- "tzdjkr6akvgkxdmo"
secret_6 <- "QB3rtACu"
scope_6 <- "emsi_open"

client_id_5 <- "d41nsww2xml7wm3e"
secret_5 <- "C4LLBeVp"
scope_5 <- "emsi_open"

client_id_4 <- "pw2zn2lexwtbas3e"
secret_4 <- "M2i5Hrjd"
scope_4 <- "emsi_open"

client_id_3 <- "74x7zmozmz8fiqud"
secret_3 <- "6stwSF9B"
scope_3 <- "emsi_open"

client_id_2 <- "duwgu3vuhlbr3vj2"
secret_2 <- "RWY09R8M"
scope_2 <- "emsi_open"

client_id <- '9doiv2cmqlaf9r0f'
secret <- 'KTefV00m'
scope <-'emsi_open'

# authentication
# All endpoints require an OAuth bearer token. 
# Tokens are granted through the Emsi Auth API at
# https://auth.emsicloud.com/connect/token and are valid for 1 hour. 
#For access to the Skills API, you must request an OAuth bearer 
#token with the scope emsi_open.

get_token <- function(client_id, secret, scope){
  url <- "https://auth.emsicloud.com/connect/token"
  payload <- str_interp("client_id=${client_id}&client_secret=${secret}&grant_type=client_credentials&scope=${scope}")
  encode <- "form"
  
  response <- VERB("POST", 
                   url, 
                   body = payload, 
                   add_headers(Content_Type = 'application/x-www-form-urlencoded'), 
                   content_type("application/x-www-form-urlencoded"), 
                   encode = encode)
  
  token_text <- content(response, "text")
  
  token_json <- fromJSON(token_text)
  
  access_token <- token_json$access_token
  
  return(access_token)
}

access_token <- get_token(client_id_7,secret_7,scope_7)

# get indeed data

data <- read_csv("utah_nj.csv")

# test out the skills pasrer!

get_skills <- function(job_description, confidence_string, access_token){
  url <- "https://emsiservices.com/skills/versions/latest/extract"
  clean_description <- str_replace_all(job_description,"\n","")
  payload <- str_c("{ \"text\": \"... ", clean_description, " ...\", \"confidenceThreshold\": ", confidence_string, " }")
  token_string <- str_interp('authorization: Bearer ${access_token}')
  encode <- "json"
  
  response <- VERB("POST", 
                    url, 
                    body = payload,
                    add_headers(
                            Authorization = token_string, 
                            Content_Type = 'application/json'), 
                    content_type("application/json"),
                   encode=encode
                   )
  
  response_text <- content(response, "text")
  
  response_json <- fromJSON(response_text)
  
  skill_type <- response_json$data$skill$type$name
  skill_name <- response_json$data$skill$name
  
  skill_df <- as_tibble(skill_name)
  colnames(skill_df) <- c("skill")
  
  skill_df <- skill_df %>%
    mutate(
      type = skill_type
    )
  
  
  return(skill_df)
}

create_skills_df <- function(original_source, job_url, job_title, company_name, state, description, confidence_threshold, access_token){
  base_df <- tibble(
    original_source = character(),
    job_url = character(),
    job_title = character(),
    company_name = character(),
    state = character(),
    description = character(),
    skill = character(),
    type = character()
  )
  
  skills_df <- get_skills(description, confidence_threshold, access_token)
  
  if (length(skills_df)==0){
    print("error with job")
    return(base_df)
  }
  
  skills_df <- skills_df %>%
                  mutate(
                    original_source = original_source,
                    job_url = job_url,
                    job_title = job_title,
                    company_name = company_name,
                    state = state,
                    description = description
                  ) %>%
                  select(original_source, job_url, job_title, company_name, 
                         state, description, skill, type)
  
  return(skills_df)
}


get_dataset_skills <- function(data_frame, confidence_threshold, access_token){
  base_df <- tibble(
    original_source = character(),
    job_url = character(),
    job_title = character(),
    company_name = character(),
    state = character(),
    description = character(),
    skill = character(),
    type = character()
  )
  
  for (row in 1:nrow(data_frame)){
    original_source = data_frame[row,"original_source"][[1]]
    job_url = data_frame[row,"job_url"][[1]]
    job_title = data_frame[row,"job_title"][[1]]
    company_name = data_frame[row,"company_name"][[1]]
    state = data_frame[row,"state"][[1]]
    description = data_frame[row,"description"][[1]]
    
    print(c(job_title, company_name, state))
    
    skills_df = create_skills_df(original_source,
                                 job_url,
                                 job_title, 
                                 company_name, 
                                 state, 
                                 description, 
                                 confidence_threshold, 
                                 access_token)
    
    base_df <- bind_rows(base_df, skills_df)
  }
  
  return(base_df)
}

cali_oregon_emsi <- get_dataset_skills(data, "0.4",access_token)

utah_nj_emsi <- get_dataset_skills(data, "0.4",access_token)

cali_oregon_utah_nj_emsi <- bind_rows(cali_oregon_emsi,utah_nj_emsi)

write.csv(cali_oregon_utah_nj_emsi, file = "cali_oregon_utah_nj_emsi.csv",
          row.names = FALSE)








