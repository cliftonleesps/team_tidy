
library(httr)
library(jsonlite)
library(RCurl)
library(xml2)
library(stringr)
library(rvest)
library(RSelenium)


# create function that takes a state string and returns an set of indeed jobs
# from that state

get_base_page <- function(state_string){
  job_string <- str_c("Data-Scientist-jobs-in-",state_string)
  url <- stringr::str_interp("https://indeed.com/${job_string}")
  
  page <- xml2::read_html(url)
  
  return(page)
}


# Create list of jobcards
## We will iterate through this later to extract job details

get_jobs <- function(html_page) {
  jobs <- html_page %>% 
    rvest::html_element('div[id="mosaic-zone-jobcards"]') %>% 
    rvest::html_elements('a[id]')
  
  return(jobs)
}

# create function that takes a job list page and returns the "next" button. We
# will reference this later after exhausting all jobcards on the current page

get_page_url <- function(html_page){
  page_scroller <- html_page %>%
    rvest::html_element('nav[role="navigation"]') %>%
    rvest::html_element('a[aria-label="Next"]')
  
  page_scroller_url <- str_c("https://indeed.com",
                             page_scroller %>% 
                               html_attr("href")
  )
}

# There is limited data on indeed job cards. Each job card includes in the HTML
# a url to the "full" job page. We will create functions now that extracts these
# urls for later crawling

get_href_list <- function(jobs_list) {
  href_list <- list()
  
  for (job in jobs_list) {
    href <- job %>% rvest::html_attr("href")
    href_list <- append(href_list, href)
  }
  
  return(href_list)
}

# create a function that takes a list of job pages, and extracts parsed data
# from those pages including job_url, job_title, company_name, job_description

pull_page_results <- function(job_href_list, state_string) {
  original_source_list = list()
  job_url_list = list()
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
    
    original_source_list <- append(original_source_list, "indeed")
    job_url_list <- append(job_url_list, new_url)
    job_title_list <- append(job_title_list, job_title)
    company_name_list <- append(company_name_list, company)
    state_list <- append(state_list, state_string)
    job_description_list <- append(job_description_list, job_description_text)
  }
  
  ret = list(original_source_list,job_url_list,job_title_list,company_name_list,state_list,job_description_list)
  
  return(ret)
}


# create wrapper function that combines the above. Takes a base_page (the
# original page after the state search) and depth. It will extract all jobs from
# a page, and continue to traverse other pages for the amount 
# specified by depth

traverse_job_search <- function(base_page, state_string, depth){
  original_source_list = list()
  job_url_list = list()
  job_title_list = list()
  company_name_list = list()
  state_list = list()
  job_description_list = list()
  
  
  for (i in seq(depth)){
    print(str_interp("page ${i}"))
    jobs <- get_jobs(base_page)
    page_url <- get_page_url(base_page)
    href_list <- get_href_list(jobs)
    page_results <- pull_page_results(href_list, state_string)
    
    original_source_list <- append(original_source_list, page_results[1])
    job_url_list <- append(job_url_list, page_results[2])
    job_title_list <- append(job_title_list, page_results[3])
    company_name_list <- append(company_name_list, page_results[4])
    state_list <- append(state_list, page_results[5])
    job_description_list <- append(job_description_list, page_results[6])
    
    #sel_driver$navigate(page_url)
    #base_page <-sel_driver$getPageSource()[[1]]
    base_page <- xml2::read_html(page_url)
    Sys.sleep(2)
    if((i %% 4) == 0){
      message("taking a break")
      Sys.sleep(8)
    }
  }
  ret = list(original_source_list,job_url_list,job_title_list,company_name_list,state_list,job_description_list)
  
  return(ret)
}


get_state_jobs <- function(state_string, depth){
  base_page <- get_base_page(state_string)
  test_results <- traverse_job_search(base_page, state_string, depth=depth)
  
  return(test_results)
}


# final wrapper function that enables the input of a state list

get_multiple_state_jobs <- function(state_list, depth) {
  base_df <- tibble(
    original_source = character(),
    job_url = character(),
    job_title = character(),
    company_name = character(),
    state = character(),
    description = character()
  )
  
  for (state in state_list) {
    print(state)
    state_results <- get_state_jobs(state,depth=depth)
    
    formatted_state_results <- conv_state_results_to_dataframe(state_results)
    
    base_df <- bind_rows(base_df, formatted_state_results)
  }
  
  return(base_df)
}


# generate data using above functions

state_list <- c("Utah",
                "New-Jersey")


utah_nj_df <- get_multiple_state_jobs(state_list, 1)

write.csv(utah_nj_df, file = "utah_nj.csv",
          row.names = FALSE)

california_jobs <- get_state_jobs("California",1)
oregon_jobs <- get_state_jobs("Oregon",1)

conv_state_results_to_dataframe <- function(state_results){
  state_df <- as_tibble(unlist(state_results[1]))
  colnames(state_df) = c("original_source")
  
  state_df <- state_df %>%
    mutate(
      job_url = unlist(state_results[2]),
      job_title = unlist(state_results[3]),
      company_name = unlist(state_results[4]),
      state = unlist(state_results[5]),
      description = unlist(state_results[6])
    )
  
  return(state_df)
}

cali_df <- conv_state_results_to_dataframe(california_jobs)

oregon_df <- conv_state_results_to_dataframe(oregon_jobs)
