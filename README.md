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

# Findings:  

## Distribution of Collected Jobs
From our analysis, there are about 227 jobs from three sources (Indeed, Stack Overflow, Linkedin)

![Distribution by Source](https://github.com/cliftonleesps/team_tidy/blob/main/images/jobs_source.png)

From the analysis of the skills obtained, we can see that for each of the job sources, there are way more hard skills required than soft skills. Also, each of the job sources showed that some sort of certifications is also required.

![Distribution by Source by Type](https://github.com/cliftonleesps/team_tidy/blob/main/images/jobs_source_type.png)

## Most Important Skills Across Sources

We were able to extract and identify 8739 skills (934 unique) pertinant to Data Science jobs from the different sources. Of the 8739 skills, 1620 were classified as "Soft Skills", while 7119 were classified as "Hard Skills". 

![Hard vs Soft](https://github.com/cliftonleesps/team_tidy/blob/main/images/hard_vs_soft.png)

While there weren't as many soft skills as hard skills present in the data, certain soft skills like Research, Innovation, Communication, Operations, Leadership, and Curiosity proved invaluable, making it to the top 30 of all skills extracted across all job sources.

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

## Statistical Testing

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

Further statistical analysis was conducted to know if there are significant difference between the proportion of hard and soft skills across all job sources: 

**Hypothesis Test:**  

```{r statistics-by-type}
hard_soft_prop <- data_source %>% count(type) %>% top_n(2) %>% mutate(prop = round((p = n/sum(n)),3))
hard_soft_prop                                    
```
Null Hypothesis: There is no difference in the proportion of hard and soft skills.  
Alternative Hypothesis: The proportion of hard skills is greater than proportion of soft skills.  


*Check conditions:*  
Sampling Independence: The sample is gotten from random Indeed, Stack Overflow, and LinkedIn job postings.  
Normality: Success - failure condition: np, n(1-p) > 10;  
```{r check-conditions}
prop_hard <- hard_soft_prop$prop[1] # proportion of hard skills
prop_soft <- hard_soft_prop$prop[2] # proportion of soft skills
n_hard <- hard_soft_prop$n[1] # number of hard skills
n_soft <- hard_soft_prop$n[2] # number of soft skills

#Check success - failure conditions
# Hard Skills
paste0("Hard Skills: np = ", n_hard*(prop_hard), " > 10, and n(1-p) = ",n_hard*(1 - prop_hard), " > 10")
# Soft Skills
paste0("Soft Skills: np = ", n_soft*(prop_soft), " > 10, and n(1-p) = ",n_soft*(1 - prop_soft), " > 10")
```
The Independence and success-failure condition are both satisfied. Therefore, a normal model can be assumed for this data.  


```{r hypothesis-test}
mu <- 0
alpha <- 0.05 # level of significance
df <- n_hard + n_soft - 2 # degree of freedom
diff_prop <- prop_hard - prop_soft # difference in proportion of hard and soft skills
SE <- sqrt(prop_hard*(1 - prop_hard)/n_hard + prop_soft*(1-prop_soft)/n_soft) # standard error for difference in proportions
Test_statistic <- (diff_prop - mu)/SE # Test statistic
p_value <- round(pt(Test_statistic, df, lower.tail = FALSE), 9) # p_value for one tail test
paste0("Since the p value is ", p_value, " which is less than ", alpha,
       ", we reject the null hypothesis at 0.05 level of significance.")
```
*Conclusion:* Since the p value is 0 which is less than 0.05, we reject the null hypothesis at 0.05 level of significance. Therefore, there is no sufficient statistical evidence that the proportion of hard skills sought for in data science job postings is equal to the proportion of soft skills sought for in data science job postings. i.e. The proportion of hard skills is greater than the proportion of soft skills.


