# Fantasy-Football-Sleeper-API-Predict
Updated 2/22/2020, Project Created on 11/20/2019

Inspiried by https://fantasyfootballanalytics.net/category/gold-mining for applying analytics to Fantasy Football.

### Intro

https://sleeper.app/, a Fantasy Football site alternative to Yahoo and ESPN, comes equipped with an API to pull in league stats. Below was a predictive tool created to determine the likely hood of making it into the playoffs based on previous team performance. This tool was used to inform my decisions when trying to assess my current trajectory and if changes were necessary. 

Originally the analysis was hosted in an R file, but was built out into a ShinyApp for easier access for Tuesdays after the final games were played and the scores were updated on Sleeper's back-end. 

Originally hosted on  https://samlederer.shinyapps.io/ffpredictsleeper/ [2/22/20 update: Currently not maintained during the off season, check back next season!]

## Prediction Method
Normal distributions are created and then over the course of N iterations, a random value within that normal distribution is selected to be the score of the team for the week. 

The winner of the week is determined for each week, and then records are totaled with total points scored in the season being the tie breaker. The average and standard deviation are not recalculated after each week as that would artificially weight the distribution. 

### Assumptions: 
* A player, and therefore team, Fantasy Football scores are normally distributed. 
* Injuries and operation of the team (choosing players to start) are not taken into account to reduce complexity and are assumed to be to the best effort of the team operator. 
* Player byes effecting the output for that week are also not taken into account. 

## Output
After falling to 4-5 this season and knowing that usually 8-6 was the record to make it to the playoffs on average, I used this tool to determine if I had to make some risky trades to offset an on paper slim chance at the playoffs. What the model provided me was the assurance that I would be still on target to make it to the playoffs:

![image](https://imgur.com/34cxi3W.png)

Even at my lowest, based on losing most early games with scores higher than the league average, I was still a little less than a coin flip to make it in.

## Improvements

I echo Billy Beane, the Moneyball star, when I think of the success of this tool: 

> “My job is to get us to the playoffs. Everything after that is f****** luck” - Billy Beane 

Version 1 of this project helped me not hit the panic button at a crucial turning point of the season.

Improvements I want to make in the future are: 
* More options in the ShinyApp to expand this to other users based on usual metrics that differ by league (Number of weeks, number of playoff teams, etc.)
* Account for bye players. I did this week over week as I had to mentally offset some predicted based on the effective value of the player that they had on bye. 
* Better export of data, most week to week numbers were saved in a Google Sheet and then plotted. 
