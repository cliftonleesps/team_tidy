# Tibble operations
library(tidyverse)

# For data cleanup
library(stringr)

# Creating tables
library(dbplyr)

# Connection to a DB
library(DBI)

# for presenting tables
library(kableExtra)

# for hitting API's
library(curl)

# for JSON parsing
library("rjson")

# for htmldecode
library(textutils)


source("../teamtidy_set_env.R")

db_connection <- dbConnect(RMariaDB::MariaDB(),
                           host=Sys.getenv("TEAMTIDY_DB_HOST"),
                           user = Sys.getenv("TEAMTIDY_DB_USER"),
                           password = Sys.getenv("TEAMTIDY_DB_PASS"),
                           dbname = 'data_science_jobs')
# rs <- dbGetQuery(db_connection, "select job_id, title, substring(description, 1, 100) as job_description from job")

job_df <- tibble(
  title = 'Senior Data Manager',
  description = "test description",
  url ="http"
  )
dbAppendTable(db_connection, "job", job_df)

# rs %>%
#   kbl() %>%
#   kable_material(c("striped", "hover"))


# Test scraping the Findwork.dev site
curl_handle <- new_handle()
handle_setopt(curl_handle, customrequest="GET")
handle_setheaders(curl_handle, Authorization = "Token 60be76cf4a00046246aa56da89ad502aaa489913")

req <- curl_fetch_memory("https://findwork.dev/api/jobs?location=nyc&search=Data+Science&sort_by=relevance", handle=curl_handle)
cat(rawToChar(req$content))

result <- fromJSON(rawToChar(req$content))




result <- fromJSON(file="findwork.dev.json")
for (i in result$results) {
  print (sprintf("id : %d", i$id))
  i$text <- stri_enc_toascii(i$text)
  dbAppendTable(db_connection, "find_work_dev", as_tibble(i))
}


for (i in result$results) {
  #print (i$text)
  print ("_______________________________________________________\n\n")
  
  if (str_detect(i$text,'\\* .+?<br/>')) {
    skills <- str_extract_all(i$text, '\\* .+?<br/>')
    print (sprintf("%s matches <br/>", i$id))

  } else if (str_detect(i$text,'<p>.+?<br/>')) {
    skills <- str_extract_all(i$text, '')
    print (sprintf("%s matches <p><br/>", i$id))
    
  } else if (str_detect(i$text,'•.+?(</a>|•|<br>)')) {
    skills <- str_extract_all(i$text, '')
    print (sprintf("%s matches •", i$id))
    
  } else if (str_detect(i$text,'●.+?<br>')) {
    skills <- str_extract_all(i$text, '')
    print (sprintf("%s matches ●", i$id))
    
  } else if (str_detect(i$text,'<li>.+?</li>')) {
    skills <- str_extract_all(i$text, '')
    print (sprintf("%s matches <li>", i$id))
    
  } else if (str_detect(i$text,'<p>.+?</p>')) {
    skills <- str_extract_all(i$text, '')
    print (sprintf("%s matches <li>", i$id))
    
  } else if (str_detect(i$text,'<br>.+?<br>')) {
    skills <- str_extract_all(i$text, '')
    print (sprintf("%s matches <br>", i$id))
    
  } else if (is.element(i$id, c(96497,95918))) {
    next
  } else {
    print (i$id)
    print (i$text)
    break
  }

  for (s in skills) {
    skill_record <- tibble(
      description = s
    )
    dbAppendTable(db_connection, "skill", as_tibble(skill_record))
  }
  
  
 # bullets <- str_extract_all(i$text, "•.+?</a>")
  
  #bullets <- str_match_all(i$text,'\\* .+?<br/>')
  #print (bullets)

    #print (nrow(bullets))
  
  # bullet <- HTMLdecode(str_extract(i$text, "•.+?</a>"))
  # hrefs <- str_extract_all(bullet, "href=\".+?\"")
  # for (h in hrefs) {
  #   print (h)
  # }
}

text <- "Aquabyte (<a href=\"https:&#x2F;&#x2F;www.aquabyte.ai\" rel=\"nofollow\">https:&#x2F;&#x2F;www.aquabyte.ai</a>, backed by NEA and Costanoa, top tier investors) is on a mission to revolutionize the sustainability and efficiency of aquaculture. It is an audacious, and incredibly rewarding mission. By making fish farming cheaper and more viable than livestock production, we aim to mitigate one of the biggest causes of climate change and help prepare our planet for impending population growth. Aquaculture is the single fastest growing food-production sector in the world, and now is the time to define how technology is used to harvest the sea for generations to come.<br>Watch our TV episode with Amazon CTO Werner Vogels here: <a href=\"https:&#x2F;&#x2F;www.youtube.com&#x2F;watch?v=YZ_qJ5JFD3I\" rel=\"nofollow\">https:&#x2F;&#x2F;www.youtube.com&#x2F;watch?v=YZ_qJ5JFD3I</a><br>Through custom underwater cameras, computer vision, and machine learning we are able to quantify fish weights, detect sea lice infestations, and generate optimal feeding plans in real time. Our product operates at three levels: on-site hardware for image capture, cloud pipelines for data processing, and a user-facing web application. As a result, there are hundreds of moving pieces and no shortage of fascinating challenges across all levels of the stack.<br>If interested, please apply at <a href=\"https:&#x2F;&#x2F;jobs.lever.co&#x2F;aquabyte&#x2F;\" rel=\"nofollow\">https:&#x2F;&#x2F;jobs.lever.co&#x2F;aquabyte&#x2F;</a><br>We&#x27;re Hiring:<br>• Senior Technical Product Manager: <a href=\"https:&#x2F;&#x2F;jobs.lever.co&#x2F;aquabyte&#x2F;80257399-0987-491a-868b-6f9a22d88a12\" rel=\"nofollow\">https:&#x2F;&#x2F;jobs.lever.co&#x2F;aquabyte&#x2F;80257399-0987-491a-868b-6f9a2...</a><br>• UI &#x2F; UX Designer: <a href=\"https:&#x2F;&#x2F;jobs.lever.co&#x2F;aquabyte&#x2F;98e64b51-fb52-42c9-a9d5-c76fb2bd6f62\" rel=\"nofollow\">https:&#x2F;&#x2F;jobs.lever.co&#x2F;aquabyte&#x2F;98e64b51-fb52-42c9-a9d5-c76fb...</a><br>• Mechanical Engineer: <a href=\"https:&#x2F;&#x2F;jobs.lever.co&#x2F;aquabyte&#x2F;4bfe8b61-e64d-4094-9eec-59090d7e1faf\" rel=\"nofollow\">https:&#x2F;&#x2F;jobs.lever.co&#x2F;aquabyte&#x2F;4bfe8b61-e64d-4094-9eec-59090...</a><br>• Sr. Embedded Software Engineer: <a href=\"https:&#x2F;&#x2F;jobs.lever.co&#x2F;aquabyte&#x2F;82467b1e-330d-4b57-8e02-9bd72de04561\" rel=\"nofollow\">https:&#x2F;&#x2F;jobs.lever.co&#x2F;aquabyte&#x2F;82467b1e-330d-4b57-8e02-9bd72...</a><br>• Director of Data Science: <a href=\"https:&#x2F;&#x2F;jobs.lever.co&#x2F;aquabyte&#x2F;f2cb0e3c-a325-46e0-9bef-65a68f6da552\" rel=\"nofollow\">https:&#x2F;&#x2F;jobs.lever.co&#x2F;aquabyte&#x2F;f2cb0e3c-a325-46e0-9bef-65a68...</a><br>• Senior Data Scientist: <a href=\"https:&#x2F;&#x2F;jobs.lever.co&#x2F;aquabyte&#x2F;c7f80cae-43c7-4e5e-89f4-f8863727b9f8\" rel=\"nofollow\">https:&#x2F;&#x2F;jobs.lever.co&#x2F;aquabyte&#x2F;c7f80cae-43c7-4e5e-89f4-f8863...</a><br>• Production Engineer (New Product Introduction Engineer): <a href=\"https:&#x2F;&#x2F;jobs.lever.co&#x2F;aquabyte&#x2F;16a843f1-e2a4-4e59-aa01-9c6a9873ba40\" rel=\"nofollow\">https:&#x2F;&#x2F;jobs.lever.co&#x2F;aquabyte&#x2F;16a843f1-e2a4-4e59-aa01-9c6a9...</a><br>• Chief of Staff to CEO: <a href=\"https:&#x2F;&#x2F;jobs.lever.co&#x2F;aquabyte&#x2F;81849eb9-08a2-4d21-9869-0967491fe9d1\" rel=\"nofollow\">https:&#x2F;&#x2F;jobs.lever.co&#x2F;aquabyte&#x2F;81849eb9-08a2-4d21-9869-09674...</a><br>• And open roles in USA (SF, NYC), Norway, and Chile : <a href=\"https:&#x2F;&#x2F;jobs.lever.co&#x2F;aquabyte&#x2F;\" rel=\"nofollow\">https:&#x2F;&#x2F;jobs.lever.co&#x2F;aquabyte&#x2F;</a>"
str_extract_all(text, "•.+?</a>")
