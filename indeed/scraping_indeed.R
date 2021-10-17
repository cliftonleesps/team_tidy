install.packages("httr","jsonlite")
install.packages("RCurl")
install.packages("rvest")

library(httr)
library(jsonlite)
library(RCurl)
library(xml2)
library(stringr)
library(rvest)
library(RSelenium)


remDr <- remoteDriver(
  remoteServerAdd = "localhost",
  port = 4445L,
  browser = "chrome"
)

remDr$open()

get_base_page <- function(state_string){
  job_string <- str_c("Data-Scientist-jobs-in-",state_string)
  url <- stringr::str_interp("https://indeed.com/${job_string}")
  #sel_driver$navigate(url)
  #page <- sel_driver$getPageSource()[[1]]
  
  page <- xml2::read_html(url)
  
  return(page)
}


# Create list of jobcards
## We will iterate through this later to extract job details

get_jobs <- function(html_page) {
  jobs <- html_page %>% 
    rvest::html_element('div[id="mosaic-zone-jobcards"]') %>% 
    rvest::html_elements('a[id]')
}


get_page_url <- function(html_page){
  page_scroller <- html_page %>%
    rvest::html_element('nav[role="navigation"]') %>%
    rvest::html_element('a[aria-label="Next"]')
  
  page_scroller_url <- str_c("https://indeed.com",
                             page_scroller %>% 
                               html_attr("href")
  )
}


get_href_list <- function(jobs_list) {
  href_list <- list()
  
  for (job in jobs_list) {
    href <- job %>% rvest::html_attr("href")
    href_list <- append(href_list, href)
  }
  
  return(href_list)
}



pull_page_results <- function(job_href_list) {
  job_title_list = list()
  company_name_list = list()
  state_list = list()
  job_description_list = list()
  
  for (i in seq(job_href_list)){
    new_url <- str_c("https://indeed.com", job_href_list[i])
    #sel_driver$navigate(new_url)
    #new_page <- sel_driver$getPageSource()[[1]]
    new_page <- xml2::read_html(new_url)
    
    job_title <- html_element(new_page, 'h1[class="icl-u-xs-mb--xs icl-u-xs-mt--none jobsearch-JobInfoHeader-title"]') %>%
      html_text2()
    
    company <- html_element(new_page, 'div[class="jobsearch-CompanyReview--heading"]') %>%
      html_text2()
    
    job_description_text <- html_element(new_page, 'div[id="jobDescriptionText"]') %>%
      html_text2()
    
    #viewJobSSRRoot <- rvest::html_element(new_page, 'div[id="viewJobSSRRoot"]')
    #full_text <- viewJobSSRRoot %>% html_text2()
    
    job_title_list <- append(job_title_list, job_title)
    company_name_list <- append(company_name_list, company)
    state_list <- append(state_list, state_string)
    job_description_list <- append(job_description_list, job_description_text)
  }
  
  ret = list(job_title_list,company_name_list,state_list,job_description_list)
  
  return(ret)
}



traverse_job_search <- function(base_page, state_string, depth){
  job_title_list = list()
  company_name_list = list()
  state_list = list()
  job_description_list = list()
  
  
  for (i in seq(depth)){
    print(str_interp("page ${i}"))
    jobs <- get_jobs(base_page)
    page_url <- get_page_url(base_page)
    href_list <- get_href_list(jobs)
    page_results <- pull_page_results(href_list)
    
    job_title_list <- append(job_title_list, page_results[1])
    job_title_list <- append(job_title_list, page_results[1])
    job_title_list <- append(job_title_list, page_results[1])
    job_title_list <- append(job_title_list, page_results[1])
    
    ret_list <- append(ret_list, job_descriptions)
    #sel_driver$navigate(page_url)
    #base_page <-sel_driver$getPageSource()[[1]]
    base_page <- xml2::read_html(page_url)
    Sys.sleep(2)
    if((i %% 4) == 0){
      message("taking a break")
      Sys.sleep(8)
    }
  }
  
  return(ret_list)
}


get_state_jobs <- function(state_string, depth){
  base_page <- get_base_page(state_string)
  test_results <- traverse_job_search(base_page, depth=depth)
  
  return(test_results)
}

get_multiple_state_jobs <- function(state_list, depth) {
  final_states <- list()
  final_results <- list()
  
  for (state in state_list) {
    print(state)
    state_results <- get_state_jobs(state,depth=depth)
    final_results <- append(final_results, state_results)
    final_states <- append(final_states, state_count)
  }
  
  return(c(final_states,final_results))
}


page <- get_base_page("New-York")

jobs <- get_jobs(page)

href_list <- get_href_list(jobs)

sample_job_string <-str_c("https://indeed.com", href_list[1])

sample_job <- xml2::read_html(sample_job_string)

company <- html_element(sample_job, 'div[class="jobsearch-CompanyReview--heading"]') %>%
            html_text2()

job_title <- html_element(sample_job, 'h1[class="icl-u-xs-mb--xs icl-u-xs-mt--none jobsearch-JobInfoHeader-title"]') %>%
  html_text2()

job_description_text <- html_element(sample_job, 'div[id="jobDescriptionText"]') %>%
  html_text2()

data <- rvest::html_element(sample_job, 'div[id="viewJobSSRRoot"]')





state_list <- c("New-York",
                "Boston",
                "Chicago",
                "Las-Angeles",
                "San-Francisco",
                "Austin")

all_jobs <- get_multiple_state_jobs(state_list = state_list, depth=5, sel_driver = remDr)


new_york_jobs <- get_state_jobs("New-York",5)

jobs <- unlist(new_york_jobs)

jobs_df <- as_tibble(jobs)

colnames(jobs_df) <- c("full_job_text")

first_job <- jobs_df[1,]

write.csv(jobs_df, file = "sample_new_york_jobs.csv",
          row.names = FALSE)


