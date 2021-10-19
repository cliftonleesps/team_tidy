# Brief
For DATA 607 Project 3, all teams must use data to answer the question, “Which are the most valued data science skills?” Consider your work as an exploration; 
there is not necessarily a “right answer.”


Reference: https://bbhosted.cuny.edu/webapps/blackboard/content/listContent.jsp?course_id=_2010110_1&content_id=_59650554_1

# Team Members:

* Alec McCabe
* Chinedu Emmanuel Onyeka
* Cliff Lee
* Preston Peck
* Santiago Torres

# Motivation:

Most of the Team Tidy members are interested in the M.S. in Data Science to upskill our portfolios and enter the Data Science job market. Finding the most valued data science skills using a quantitative and qualitative approach identifies where we should focus our efforts in order to develop into Data Scientists.

# Approach:

Our team took a literal interpretation of the prompt “all teams must use data to answer the question, ‘Which are the most valued data science skills’” and decided to survey the existing job market to answer that question. We identified three key job posting sites:
Stack Overflow - a popular, public platform for developers and technologists
LinkedIn - a professional network
Indeed - a job site

# Objective:

We used these disparate sites to capture a statistically significant sample of Data Science job postings and produced a comprehensive answer of the most valued data science related skills.

# Data Collection:

We utilized rvest and selenium to scrape data from our identified sources into separate dataframe outputs organized by at minimum the following key data elements:

* job_title
* description
* company_name

# Data Transformation:

After scraping our identified sources, we created a script skills_extraction.R which queries the EMSI API in order to extract skills from job descriptions. EMSI’s Open Skill Library returns a standardized set of skills split by hard and soft skills.(license)

We then inserted each of the source outputs into a normalized SQL database for persistent storage.

In order to fulfill the requirement of determining the most desirable skills for Data Science jobs, we settled on a basic, two table database layout. The job table is the parent table and has a one to many relationship to the skills table. Querying for the most frequent skills per job was simple from this design.


![SQL ER](https://github.com/cliftonleesps/team_tidy/blob/main/images/er_diagram.png)



# Findings:  

## Distribution of Collected Jobs

## Most Important Skills Across Sources

From our analysis of over 150 jobs from three sources (Indeed, Stack Overflow, Linkedin), we were able to extract and identify 8739 skills (934 unique) pertinant to Data Science jobs. Of the 8739 skills, 22% were classified as "Soft Skills", and the remainder were classified as "Hard Skills".

While there weren't as many soft skills as hard skills present in the data, certain soft skills proved invaluable, making it to the top 25 of all skills extracted across all job sources.

![All Skills](/images/all_skills.png)

## Most Important Hard Skills Skills Across Sources

In terms of Hard Skills, we were not surprised with the final results. Included in the top ten are skills related to:
* coding and data manipulation (python, R, SQL)
* math and statistics (statistical modeling, machine learning, statistics)

![Hard Skills](/images/hard_skills.png)

## Most Important Soft Skills Skills Across Sources

As we saw before, the most important soft skills are centered around things like:
* Team Work, working with others (communication, operations, leadership)
* Problem Solving (innovation, problem solving, creativity)

![Top 10 Soft Data Science Skills](https://github.com/cliftonleesps/team_tidy/blob/main/images/soft_skills.png)

## Distribution of Hard and Soft Skills Across Sources

We wanted to see if any one source tended to have more job postings with a higher proportion of "hard skills". Based on the below boxplot, we can see that all sources have roughly the same level of hard skills proportion. It is worth mentioning that Stack Overflow seems to have a slightly higher median than the other groups, but it also has a significantly smaller range.

![Source Proportion](https://github.com/cliftonleesps/team_tidy/blob/main/images/source_proportion.png)

We can use a statistical test to answer the question, "Does Stack Overflow's distribution of hard_proportion in jobs have a statistically signficant difference than the jobs of other sources?

Using a two tailed T test, we confirm that (despite visuals from the above boxplot), there is no significant difference between Stack Overflow and the other sources.

> * Two Sample t-test\n
> * data:  so_props and other_props\n
> * t = 1.3536, df = 161, p-value = 0.1778
> * alternative hypothesis: true difference in means is not equal to 0
> * 95 percent confidence interval:
> *  -0.0168604  0.0903353
> * sample estimates:
> * mean of x mean of y
> * 0.8475232 0.8107858


