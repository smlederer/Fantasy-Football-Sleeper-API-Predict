#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)

# Define server logic required:
shinyServer(function(input, output) {

  output$TableOutput <- renderDataTable({
    
    
    #Initialize Required Libraries
    if (!require(tidyverse)) install.packages('tidyverse')
    library(tidyverse)
    
    if (!require(curl)) install.packages('curl')
    library(curl)
    
    if (!require(jsonlite)) install.packages('jsonlite')
    library(jsonlite)
    
    
    ####1. SCRAPE####
    #Using curl library, append the input to the end of the sleeper app api and then collect the users in the league and the scores for each week. 
    
    url = 'https://api.sleeper.app/v1/league/'
    id = input$SleeperID
    req = curl_fetch_memory(paste0(url,id,'/users'))
    users_in_league = fromJSON(prettify(rawToChar(req$content)))
    
    #Scores table does not have user ID's, import the users in league table to append thsoe.
    DisplayName2owner = users_in_league %>% select(user_id,display_name)
    
    req2 = curl_fetch_memory(paste0(url,id,'/rosters'))
    rosters_in_league = fromJSON(prettify(rawToChar(req2$content)))
    
    #Connect the owners to the roster ID that they own. 
    Owner2Roster = rosters_in_league %>% select(roster_id,owner_id)
    
    #Create a match table for the final output. 
    user_match_table = merge(DisplayName2owner,Owner2Roster,by.x = 'user_id',by.y = 'owner_id')
    
    
    #Each week is stored in a different address in the sleeper.api, so iterate over all weeeks of the season.
    #Incomplete weeks import as NAs.
    #All append into a final data frame. 
    final_df = data.frame()
    for (j in seq(1,14)){
      matchup_week_url = paste0(url,id,'/matchups/',j)
      
      fetch = curl_fetch_memory(matchup_week_url)
      fetch_df = fromJSON(prettify(rawToChar(fetch$content)))
      
      fetch_df_reduce = fetch_df %>% select(roster_id,points,matchup_id) %>% mutate(week=j)
      
      final_df = rbind(final_df,fetch_df_reduce)
    }
    
    
    ####2. PREDICT####
    
    #Rename columns
    x = final_df
    names(x) = c('TeamID','Score','Matchup_ID','week')
    
    #Split Data. 
    #Train data is for determining params of Norm(mean, std)
    #Test data is what is being predicted on.
    
    #Train = records we have
    #Test = weeks yet to be played
    train = x %>% filter(!is.na(Score)) 
    test = x %>% filter(is.na(Score))
    
    
    #From train, determine mean and std for each team
    
    teamdb = train %>% group_by(TeamID) %>% summarise(mean = mean(Score),sd = sd(Score))
    
    #Append the values for each of the teams onto the test data frame for ease of use. 
    
    test_teamdb = merge(test,teamdb,by.x = 'TeamID',by.y = 'TeamID')
    
    #Number of iterations for the random polling of the normal distributions.
    
    runs = 1000
    
    #Initialize data frame to store the iterations
    
    master_df = data.frame()
    
    for (i in seq(1:runs)){
      
      #Calculate a random result within the mean and standard deviation of each user's metrics. 
      #Poll a random number for each of the teams for each of the weeks. 
      #Then determine which score is higher and calcualte the wins (twin) and losses (tlosses) cumulative. 
      
      test_pred = test_teamdb %>% mutate(predict = rnorm(n(),mean=mean,sd))
      
      test_pred_user = test_pred %>% group_by(week,Matchup_ID) %>% mutate(the_better = TeamID[which.max(predict)],win =ifelse(TeamID == the_better,1,0)) %>% ungroup()
      
      test_pred_tot = test_pred_user %>% group_by(TeamID) %>% summarise(wins = sum(win),losses = sum(win=="0"),totalpoints = sum(predict))
      
      train_user = train %>% group_by(week,Matchup_ID) %>% mutate(the_better = TeamID[which.max(Score)],win =ifelse(TeamID == the_better,1,0)) %>% ungroup()
      
      train_tot = train_user %>% group_by(TeamID) %>% summarise(wins = sum(win),losses = sum(win=="0"),totalpoints = sum(Score))
      
      finalresult = merge(train_tot,test_pred_tot,by = 'TeamID') %>% mutate(tWins = wins.x+wins.y,tLoss = losses.x+losses.y,tPoints = totalpoints.x+totalpoints.y)
      finalresult2 = finalresult %>% select(TeamID,tWins,tLoss,tPoints) %>% arrange(desc(tWins),desc(tPoints))
      
      master_df = rbind(master_df,finalresult2 %>% head(input$Playoffs))
    }
    
    
    breakdown = master_df %>% group_by(TeamID) %>% summarise(count = n(),averagewins = mean(tWins)) %>% mutate(percent_chance = count/runs) %>% arrange(desc(percent_chance))
    
    #append names of owners
    
    final_breakdown = user_match_table %>% select(-user_id) %>% merge(breakdown,by.x = 'roster_id',by.y = 'TeamID',all = T)
    
    #final arrangements. 
    final_breakdown %>% arrange(desc(percent_chance))
    
    

  })
  
})
