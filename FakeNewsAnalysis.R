##### Fake News Analysis #####

# libraries
library(caret)
library(tidyverse)

# read in data
setwd("~/Documents/GitHub Projects/FakeNews/")

train <- read.csv("train.csv")
test <- read.csv("test.csv")
fakeNews <- bind_rows(train = train, test = test, .id = "Set")
fakeNewsClean <- vroom::vroom("~/Documents/GitHub Projects/FakeNews/CleanFakeNews.csv")

fakeNewsClean <- fakeNewsClean %>%
  replace(is.na(.), 0)

fakeNewsClean$isFake <- as.factor(fakeNewsClean$isFake)

fakeNewsModel <- train(form = isFake ~.,
                    data = fakeNewsClean %>% select(-Id, -Set, -language.x),
                    method = "glmboost",
                    tuneLength = 2,
                    trControl = trainControl(
                      number = 20))

preds <- as.integer(predict(fakeNewsModel, newdata = fakeNewsClean %>% filter(Set == "test")) >= 0.5)
submission <- data.frame("id" = fakeNewsClean %>% filter(Set == "test") %>% select(Id), "label" = preds)

write.csv(x = submission, file="~/Documents/GitHub Projects/FakeNews/Submissions2.csv", row.names = FALSE)  

heaton <- vroom::vroom("~/Documents/GitHub Projects/FakeNews/CleanFakeNews.csv")
