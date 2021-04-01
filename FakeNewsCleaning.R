##### Fake News #####

# libraries
library(tidyverse)
library(tidytext)
library(stopwords)

##  read in data

setwd("~/Documents/GitHub Projects/FakeNews/")

train <- read.csv("train.csv")
test <- read.csv("test.csv")
fakeNews <- bind_rows(train = train, test = test, .id = "Set")

train %>% group_by(author) %>% 
  summarise(count = n()) %>% 
  arrange(desc(count))

##  Author languages
fakeNews <- fakeNews %>%
  mutate(author_lang = textcat::textcat(author))

author_language <- fakeNews %>% count(author_lang) %>%
  arrange(desc(n))
  # print(n = Inf)


##  Text languages
fakeNews <- fakeNews %>%
  mutate(text_lang = textcat::textcat(text))
text_language <- fakeNews %>% count(text_lang) %>%
  arrange(desc(n))

##  Compare author languages and text languages
# replace NAs with zeros
fakeNews <- fakeNews %>%
  replace(is.na(.), 0)

##  check to see if there are any missing data
sum(is.na(fakeNews$author_lang))
sum(is.na(fakeNews$text_lang))

##  create binary variable for matching languages
for (i in 1:nrow(fakeNews)) {
  if (fakeNews$author_lang[i] == fakeNews$text_lang[i]) {
    fakeNews$same_lang[i] = 1
  } else {
    fakeNews$same_lang[i] = 0
  }
}

##  select only the matching languages column
match <- fakeNews %>% filter(same_lang == 1)
write.csv(x = match, file = "~/Documents/GitHub Projects/FakeNews/match.csv")

match_csv <- vroom::vroom("~/Documents/GitHub Projects/FakeNews/match.csv")

match <- match_csv %>%
  mutate(language = fct_collapse(author_lang,
                               english = c("english", "middle_frisian", "scots", "catalan"),
                               russian = c("russian-koi8_r", "russian-iso8859_5")))

match <- match %>%
  mutate(language = fct_lump(author_lang, n = 6)) # %>% group_by(language) %>% summarise(n())

sw <- bind_rows(get_stopwords(language = "en"), # English
                get_stopwords(language = "ru"), # Russian
                get_stopwords(language = "es"), # Spanish
                get_stopwords(language = "de"), # German
                get_stopwords(language = "fr")) # French

##  run a tfidf to find the word count
tidyNews <- match %>% unnest_tokens(tbl = ., output = word, input = text)

## Count of words in each article
news_wc <-  tidyNews %>%
  anti_join(sw) %>% 
  count(id, word, sort = TRUE)

## Number of non-stop words per article
all_wc <- news_wc %>% 
  group_by(id) %>% 
  summarize(total = sum(n))

## Join back to original df and calculate term frequency
news_wc <- left_join(news_wc, all_wc) %>%
  left_join(x = ., y = fakeNews %>% select(id, title))
news_wc <- news_wc %>% mutate(tf = n/total)
a_doc <- sample(news_wc$title, 1)

## Find the tf-idf for the most common p% of words
word_count <- news_wc %>%
  count(word, sort = TRUE) %>%
  mutate(cumpct = cumsum(n) / sum(n))
top_words <- word_count %>% filter(cumpct < 0.50)
news_wc_top <- news_wc %>% filter(word %in% top_words$word) %>%
  bind_tf_idf(word, id, n)
true_doc <- sample(fakeNews %>% filter(label == 0) %>% pull(title), 1)

#################################
## Merge back with fakeNews data ##
#################################

## Convert from "long" data format to "wide" data format
## so that word tfidf become explanatory variables
names(news_wc_top)[1] <- "Id"
news_tfidf <- news_wc_top %>%
  pivot_wider(id_cols = Id,
              names_from = word,
              values_from = tf_idf)

# replace NAs
news_tfidf <- news_tfidf %>%
  replace(is.na(.), 0)

# merge back with fakeNews dataset
names(fakeNews)[c(2,6)] <- c("Id", "isFake")
fakeNews_tfidf <- left_join(fakeNews, news_tfidf, by = "Id")

## Remaining articles with NAs all have missing text so should get 0 tfidf
fakeNews_clean <- fakeNews_tfidf %>%
  select(-isFake, -title, -author.x, -text) %>% 
  replace(is.na(.), 0) %>% 
  left_join(fakeNews_tfidf %>% select(Id, isFake, title, author.x, text),., by = "Id")

write_csv(x = fakeNews_clean %>% select(-author.x, -title, -text),
          path = "~/Documents/GitHub Projects/FakeNews/fakeNews_clean.csv")




