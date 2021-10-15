library(httr)
library(jsonlite)
library(tidyverse)
library(stringr)

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

access_token <- get_token(client_id,secret,scope)

# get indeed data

data <- read_csv("ny_boston_chicago.csv")

colnames(data) <- c("job_title","company_name","state","description")


# test out the skills pasrer!

get_skills <- function(job_description, confidence_string, access_token){
  url <- "https://emsiservices.com/skills/versions/latest/extract"
  clean_description <- str_replace_all(job_description,"\n","")
  payload <- str_interp("{ \"text\": \"${clean_description}\", \"confidenceThreshold\": ${confidence_string} }")
  encode <- "json"
  token_string <- str_interp('Authorization: Bearer ${access_token}')
  
  response <- VERB("POST", 
                    url, 
                    body = payload, 
                    add_headers(
                            Authorization = token_string, 
                            Content_Type = 'application/json'), 
                    content_type("application/json"), 
                    encode = encode)
  
  response_text <- content(response, "text")
  
  response_json <- fromJSON(response_text)
  
  skills <- response_json[["data"]][["skill"]][["name"]]
  
  return(skills)
}

test_job <- data$description[10]

skills <- get_skills(test_job, "0.6", access_token)

skills




