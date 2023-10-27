library(tidyverse)
library(readr)
library(funModeling)
library(naniar)
library(GGally)
library(corrplot)

options(scipen = 100, digits = 4)

# unzip the file
unzip("owid-covid-data.zip")

# read the data
covid_data <- read_csv("owid-covid-data.csv")

# observing the data
covid_data %>% view()
covid_data %>% str()

# selecting the Europe continent for further analysis

covid_1 <- covid_data %>% filter(continent == 'Europe') 

# structuring the covid_1 data
covid_1 %>% view()
covid_1 %>% str()

## checking outliers and missing values

covid_1 %>% df_status()
covid_1 %>% freq()
covid_1 %>% plot_num()
covid_1 %>% summary()

# filtering out the variables from the main dataset

covid_1 %>% select(3,4,5,6,8,9,32,36,37,48,54,56,57,58,59,63) -> covid_1

## treating na_values

covid_1 %>% is.na() %>% sum()

covid_1 %>% nrow()
covid_1 %>% ncol()

# na viz
gg_miss_var(covid_1, show_pct = TRUE) + labs(title = "Visualizing Missing Values")
gg_miss_var(covid_1, facet = location,show_pct = TRUE) +
  labs(title = "Visualizing Missing Values location wise")


# selecting the date as all europe countries got affected by COVID-19

countries <- c('Spain', 'France', 'United Kingdom', 
               'Poland','Russia','Italy', 
               'Germany','Ukraine','Romania','Hungary')

covid_1 %>% filter(location %in% countries) %>% 
  filter(date >= '2020-03-01') -> covid_1

covid_1$month <- month.abb[month(ymd(as.Date(covid_1$date)))]

covid_1 %>% relocate(month, .before = total_cases) -> covid_1


# treating na

covid_1 %>%
  mutate_at(vars('people_fully_vaccinated','new_cases','people_vaccinated','stringency_index'),
            ~replace_na(., 0)) -> covid_1

covid_1 %>% group_by(location) %>% 
  # group_by(month) %>%  
  mutate_at(vars(c(4,6:8,12:17)),
            ~replace_na(.,mean(., na.rm=TRUE))) -> covid.model.1

sum(is.na(covid.model.1)) # counting na values after treating

## checking for duplicated rows 
covid.model.1 %>% distinct() %>% nrow()

# total no. of rows and distinct rows are equal
(covid.model.1 %>% distinct() %>% nrow()) == (covid.model.1 %>% nrow())

## cheking for outliers
covid.model.1 %>%
  ggplot(aes(x = total_cases , color = location)) + geom_boxplot() + 
  labs(title = 'Outliers in Total Cases')

covid.model.1 %>%
  ggplot(aes(x = total_deaths,color = location)) + geom_boxplot()+
  labs(title = 'Outliers in Total Deaths')

covid.model.1 %>%
  ggplot(aes(x = new_cases,color = location)) + geom_boxplot()+
  labs(title = 'Outliers in Total Cases')

covid.model.1 %>%
  ggplot(aes(x = positive_rate,color = location)) + geom_boxplot()+
  labs(title = 'Outliers in Positive Rate')

covid.model.1 %>%
  ggplot(aes(x = new_deaths ,color = location)) + geom_boxplot()+
  labs(title = 'Outliers in New Deaths')

covid.model.1 %>%
  ggplot(aes(x = stringency_index ,color = location)) + geom_boxplot()+
  labs(title = 'Outliers in Stringency Index')


## Treating Outliers by making the values noramlized
scaling_outliers <- function(x){
  quant <- quantile(x, probs=c(.25, .75))
  cap <- quantile(x, probs=c(.05, .95))
  q <- 1.5 * IQR(x, na.rm = T)
  x[x < (quant[1] - q)] <- cap[1]
  x[x > (quant[2] + q)] <- cap[2]
  return(x)
}

covid.model.1 %>% group_by(location) %>% 
  mutate_at(vars('total_cases','total_deaths','new_deaths',
                 'new_cases','positive_rate','stringency_index'),
            ~scaling_outliers(.)) -> covid.model.1

## looking to the outliers graphs again 
covid.model.1 %>%
  ggplot(aes(x = total_cases , color = location)) + geom_boxplot()

covid.model.1 %>%
  ggplot(aes(x = total_deaths,color = location)) + geom_boxplot()

covid.model.1 %>%
  ggplot(aes(x = new_cases,color = location)) + geom_boxplot()

covid.model.1 %>%
  ggplot(aes(x = positive_rate,color = location)) + geom_boxplot()

covid.model.1 %>%
  ggplot(aes(x = new_deaths ,color = location)) + geom_boxplot()


## plotting graphs for better understanding of the variables

covid.model.1 %>% 
  group_by(location) %>% summarise(Value = max(total_deaths)) %>% 
  ggplot(aes(x = reorder(location, -Value), y = Value)) + 
  geom_bar(stat = 'identity', width = 0.5, fill = 'maroon')+
  theme(axis.text.x = element_text(angle = 45, vjust = 0.5, hjust=1))+
  labs(title = "Covid-19 Total Death Cases in Europe", x= "Location", y= "Daily confirmed cases") +
  theme(plot.title = element_text(hjust = 0.5))

covid.model.1 %>% 
  ggplot(aes(x = month, y = total_cases)) + 
  geom_bar(stat = 'identity', width=0.5, color = 'dark blue')+
  theme(axis.text.x = element_text(angle = 45, vjust = 0.5, hjust=1))+
  labs(title = "Covid-19 Total Cases in Europe", x= "Months (grouped by year 2020-2022)", y= "Total cases") +
  theme(plot.title = element_text(hjust = 0.5))

covid.model.1 %>% 
  ggplot(aes(x = month, y = stringency_index)) + 
  geom_bar(stat = 'identity', width=0.5, color = 'dark blue')+
  theme(axis.text.x = element_text(angle = 45, vjust = 0.5, hjust=1))+
  labs(title = "Covid-19 Stringency Effect", x= "Months (grouped by year 2020-2022)", y= "Stringency_index") +
  theme(plot.title = element_text(hjust = 0.5))

covid.model.1 %>% 
  ggplot(aes(x = date, y = stringency_index)) + 
  geom_bar(stat = 'identity', width=0.5, color = '#eba834')+
  theme(axis.text.x = element_text(angle = 45, vjust = 0.5, hjust=1))+
  labs(title = "Covid-19 Stringency Effect", x= "Every Month", y= "Stringency Index") +
  theme(plot.title = element_text(hjust = 0.5))+
  scale_x_date(date_labels="%b %y",date_breaks  ="1 month")

covid.model.1 %>% group_by(month) %>% summarise(Value = max(total_deaths)) %>% 
  ggplot(aes(x = reorder(month, -Value), y = Value))+ 
  geom_bar(stat = 'identity', width=0.5, color = 'blue')+
  theme(axis.text.x = element_text(angle = 45, vjust = 0.5, hjust=1))+
  labs(title = "Covid-19 Effect on total Deaths", x= "months", y= "Total Deaths") +
  theme(plot.title = element_text(hjust = 0.5))


## Correlation Matrix

cor.covid <- covid.model.1[,c(4:17)]
cor(cor.covid)

# correlation plot
corrplot(cor(cor.covid), method = 'number',type = 'full',addCoef.col="black"
         ,number.cex=0.50, tl.cex = 0.5, cl.cex = 0.5)
# ggpairs(cor(cor.covid))

## data is not normal so we have to normalize the data

normalize <- function(x){
  return ((x-min(x)) / (max(x)-min(x)))
}

data.norm <- as.data.frame(lapply(covid.model.1[,-c(1:7)], normalize))
data.norm <- cbind(data.norm, covid.model.1[,c(1:7)])

# splitting the data in 80:20
## split data is splitted having all the continents in train and test data. 

set.seed(100)

train <- data.norm %>%
  group_by(location) %>%
  sample_frac(0.8)
test <- data.norm %>%
  group_by(location) %>%
  sample_frac(0.2)

## generating linear model 

lm.model <- lm(total_deaths ~ new_cases + total_cases + people_vaccinated + 
                 people_fully_vaccinated +
                 new_deaths + positive_rate + stringency_index +
                 male_smokers + diabetes_prevalence+
                 cardiovasc_death_rate + female_smokers + 
                 human_development_index+ gdp_per_capita, data = train)

summary(lm.model)

ggplot(data = train, aes(x = lm.model$residuals)) +
  geom_histogram(fill = 'steelblue', color = 'black') +
  labs(title = 'Histogram of Residuals', x = 'Residuals', y = 'Frequency')

## plotting the model
par(mfrow=c(2,2))
plot(lm.model)
par(mfrow=c(1,1))

model.predict <- predict(lm.model,test)


plot(x = model.predict, y= test$total_deaths,
     main = "Observed vs Pedicted Values",
     xlab = "Predicted Values",
     ylab = "Observed Values") + 
  abline(a = 0, b=1,col = 'red', lwd = 2) 

# accuracy of the Model
rsq <- function (x, y) cor(x, y) ^ 2
rsq(model.predict, test$total_deaths)

## plotting graph for the observing predicted and actual values

test_dt %>% 
  mutate(Dates = format(as.Date(date), "%Y-%m")) %>% 
  group_by(Dates) %>% 
  dplyr::summarize(avg_act = sum(total_deaths), avg_pred = sum(`.`)) -> date_by_group

date_by_group %>% 
  ggplot(aes(x=Dates, y=avg_act, group = 1, color = 'Actual'))+
  geom_line()+
  geom_line(aes(y = avg_pred,group = 1, color = 'Predicted'))+
  scale_color_manual(values=c("green", "red"))+
  theme_classic()+
  theme(axis.text.x = element_text(angle = 45, vjust = 0.5, hjust=1))+
  labs(title = 'Actual vs Predicted Total Deaths amongst Top 10 Countries',
       y = 'Total Deaths', x = 'Month_Year')

