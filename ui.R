library(shiny)

fluidPage(
  titlePanel("NBA visualization"),
  sidebarLayout(
    sidebarPanel(
      selectInput("player", "Choose a player:",
              c("James Harden","Stephen Curry","Kevin Durant","Russell Westbrook","LeBron James","Kawhi Leonard","Chris Paul","Kyle Lowry","Isaiah Thomas","Giannis Antetokounmpo")
      ),
      radioButtons("plot","Which shooting stat do you want to know?",
              c("Accuracy and proportion of shot types"=1,"Time before shot clock"=2,"Under different defensive pressure"=3,"Three pointers vs Two pointers"=4,"Accuracy by game time remained"=5,"Shot chart by shots location"=6,"Shooting accuracy of different region"=7)
      )
    ),  
    mainPanel(tabsetPanel(
      tabPanel("Visualization",
            #Wrapping plots in a fluidRow provides easy control over individual plot attributes
            fluidRow(
             column(width=8,height=10,plotOutput("plot1")),
             column(width=8,height=10,plotOutput("plot2"))
            ) 
      )
    ))
  )  
)
