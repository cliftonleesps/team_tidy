library(httr)
library(jsonlite)
library(tidyverse)
library(stringr)

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

get_skills <- function(description, confidence_threshold, access_token){
  url <- "https://emsiservices.com/skills/versions/latest/extract"
  clean_description <- description %>% str_replace_all("\n","") %>% str_replace_all("\r","")
  payload <- str_c("{ \"text\": \"... ", clean_description, " ...\", \"confidenceThreshold\": ", confidence_threshold, " }")
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

get_dataset_skills <- function(df, confidence_threshold, access_token){
  base_df <- tibble(
    job_title = character(),
    company_name = character(),
    state = character(),
    description = character(),
    skill = character(),
    type = character()
  )
  
  for (row in 1:nrow(df)){
    job_title = df[row,"job_title"][[1]]
    company_name = df[row,"company_name"][[1]]
    state = df[row,"state"][[1]]
    description = df[row,"description"][[1]]
    
    print(c(job_title, company_name, state,description))
    
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

