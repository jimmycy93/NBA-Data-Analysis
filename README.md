# NBA Data Analysis

##Project introduction
   
   This project aims to demonstrate my skills of scraping data, cleaning data, graphing data, and forming stories from data. In order to do so, I picked my favorite sport, basketball, and use the data from [NBA Stats](http://stats.nba.com/) to create some analyis. This project sticks to shooting stats and for the purpose of this project, I use shot chart data(shots from different shot location, shot region,..etc) and shot dashboard data(shots by time on shotclock, distance from closest defender,..etc) of ten best players of the league in my opinion. The project was broken into three parts, each described as below:
    
    
1. Grabbing NBA data - The goal for this part is to scrape raw data from [NBA Stats](http://stats.nba.com/) using API, and clean the scraped Json format data into nice and clean CSV files.
    
2. Building shiny application - Since there are ten players in total, graphing each of their stats on same page seems to be messy. Therefore I choose to build an interactive application via Shiny, by clicking users can view exploratory analysis sorted by player names and graph types. The link to the application is provided in next section. 
   
3. Constructing player analysis - The previous part only produce graphs without interpreting, therefore I constructed an data analysis of comparison between my favorite player, James Harden, and other nine MVP reward competitors. The analysis aims to measure the shooting performance by customized graphs and interpretation. Same as the previous part of project, the link to the work is provided in next section. 
   
##Links to project

1. [Shiny Application](https://jimmycy93.shinyapps.io/Exericises/)

2. [Player Analysis](http://rpubs.com/jimmycy93/252619)

##File description

   Code and files are uploaded to this repository, each described as below:
   
1. [GrabNBA.rmd] (https://github.com/jimmycy93/NBA-data-analysis/blob/master/GrabNBA.rmd) - Code for scaping and cleaning data

2. [JamesHarden.rmd] (https://github.com/jimmycy93/NBA-data-analysis/blob/master/JamesHarden.rmd) - Code for Player Analysis

3. [Shotchart.csv] (https://github.com/jimmycy93/NBA-data-analysis/blob/master/Shotchart.csv) - Cleaned csv file of shot chart data

4. [Shotdashboard.csv] (https://github.com/jimmycy93/NBA-data-analysis/blob/master/Shotdashboard.csv) - Cleaned csv file of shot dashboard data   

5. [aveLeague.csv] (https://github.com/jimmycy93/NBA-data-analysis/blob/master/aveLeague.csv) - Cleaned csv file of summarized shot chart data of league average

6. [server.R] (https://github.com/jimmycy93/NBA-data-analysis/blob/master/server.R) - Code for the server part of shiny application

7. [ui.R] (https://github.com/jimmycy93/NBA-data-analysis/blob/master/ui.R) - Code for the user interface part of shiny application
