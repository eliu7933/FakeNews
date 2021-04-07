# FakeNews
An analysis to determine what factors such as words or authors could best predict what would constitute a fake news article. The files included in this project are the README.md file which give an overview of the project and necessary code files, a .gitignore file which tells github to ignore certain files, a test.csv and train.csv file which includes the fake news data, and a FakeNewsCleaning.R and a FakeNewsAnalysis.R file which performs the cleaning of the dataset as well as the prediction analysis.

Methods that were used in this analysis were feature engineering and target encoding to create a dataset that included the most commonly used words in the data's articles. Discrepancies between language of the author and of the text files were first used to filter out possible fake news articles. The text files were also sorted by language and the function tf_idf was used to determine commonly used words between selected articles. 

Prediction modelling methods included glmboosting methods with various differences in tuning parameters.
