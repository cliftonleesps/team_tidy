library(httr)
library(jsonlite)
library(tidyverse)
library(stringr)

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

access_token <- get_token(client_id_2,secret_2,scope_2)

# get indeed data

data <- read_csv("ny_boston_chicago.csv")

colnames(data) <- c("job_title","company_name","state","description")


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

test_job <- data$description[16]

test_job

new_test<- get_skills(test_job, "0.1", access_token)

create_skills_df <- function(job_title, company_name, state, description, confidence_threshold, access_token){
  base_df <- tibble(
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
                    job_title = job_title,
                    company_name = company_name,
                    state = state,
                    description = description
                  ) %>%
                  select(job_title, company_name, state, 
                         description, skill, type)
  
  return(skills_df)
}

length(new_test)

job_title = data[1,"job_title"][[1]]
company_name = data[1,"company_name"][[1]]
state = data[1,"state"][[1]]
description = data[1,"description"][[1]]

test_df <- create_skills_df(job_title, 
                            company_name, 
                            state, 
                            description, 
                            "0.6",
                            access_token)

description




get_dataset_skills <- function(data, confidence_threshold, access_token){
  base_df <- tibble(
    job_title = character(),
    company_name = character(),
    state = character(),
    description = character(),
    skill = character(),
    type = character()
  )
  
  for (row in 1:nrow(data)){
    job_title = data[row,"job_title"][[1]]
    company_name = data[row,"company_name"][[1]]
    state = data[row,"state"][[1]]
    description = data[row,"description"][[1]]
    
    print(c(job_title, company_name, state))
    
    skills_df = create_skills_df(job_title, 
                                 company_name, 
                                 state, 
                                 description, 
                                 confidence_threshold, 
                                 access_token)
    
    base_df <- bind_rows(base_df, skills_df)
  }
  
  return(base_df)
}

all_skills_df <- get_dataset_skills(data, "0.7",access_token)


write.csv(all_skills_df, file = "indeed_skills_df_fixed.csv",
          row.names = FALSE)

test_read <- read_csv("indeed_skills_df_fixed.csv")

test_read %>%
  ggplot() +
  geom_bar(aes(x=type))

length(unique(test_read$skill))