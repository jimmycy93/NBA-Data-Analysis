library(shiny)
library(dplyr) #for data manipulation
library(tidyr) #for reshaping data
library(ggplot2)
library(scales) #for labels as percentage
library(RCurl)#for getting url content
library(jpeg) #for reading JPEG file
library(grid) #for rendering a raster grob


#read the csv files, make sure it is in your working directory
shotchart<-read.csv("Shotchart.csv")
shotdashboard<-read.csv("Shotdashboard.csv")
averageleague<-read.csv("aveLeague.csv")

#modify the averageleague dataframe's FG% column and add additional location information (mean coordinate of all shots in particular region)
all<-shotchart%>%group_by(SHOT_ZONE_BASIC,SHOT_ZONE_AREA,SHOT_ZONE_RANGE)%>%summarise(LOCX=mean(LOC_X),LOCY=mean(LOC_Y)) #calculate the mean location for each region

"%ni%" <- Negate("%in%")   #create a new operator, which is the opposite of %in%
all<-filter(all,SHOT_ZONE_AREA%ni%"Back Court(BC)") #eliminate back court shots
averageleague<-filter(averageleague,SHOT_ZONE_AREA%ni%"Back Court(BC)") #eliminate back court chots

averageleague$LOCX<-all$LOCX
averageleague$LOCY<-all$LOCY
averageleague$FG_PCT<-percent(round(averageleague$FG_PCT,digits=3)) #turn Field goal percentage into percentage form

#create a blank theme for each plot
blank_theme <- theme_minimal()+
  theme(
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    panel.border = element_blank(),
    panel.grid=element_blank(),
    axis.ticks = element_blank(),
    plot.title=element_text(size=12, face="bold")
  )

function(input, output){
  
  output$plot1 <- renderPlot({
    if(input$plot==1){
      #create a pie chart of the proportion of different shot type
      subset<-filter(shotdashboard,PLAYER_NAME%in%input$player&CLASS%in%"GeneralShooting")
      type<-subset$SHOT_TYPE
      value<-subset$FGA_FREQUENCY
      bp<-ggplot(subset,aes(x="",y=value,fill=type))+
        geom_bar(width=1,stat="identity")
      pie <- bp + 
        coord_polar("y", start=0)+
        ggtitle("Proportion of shot types")+
        scale_y_continuous(labels=percent)+
        blank_theme+
        theme(legend.position = "bottom")
      print(pie)
    }
    if(input$plot==2){
      #create a line plot for 2 point FG% by shotclock time left
      subset<-filter(shotdashboard,PLAYER_NAME%in%input$player&CLASS%in%"ShotClockShooting")
      subset<-subset[1:6,]
      timeleft<-subset$SHOT_TYPE
      #reorder the "timeleft" variable
      timeleft<-factor(timeleft,levels = c("22-24","18-22","15-18","07-15","04-07","00-04"))
      FG2<-subset$FG2_PCT
      line<-ggplot(subset,aes(x=timeleft,y=FG2))+
        geom_point(color="#00BA38",size=3)+
        geom_line(aes(group=1),color="#00BA38",size=1)+
        ggtitle("2 points FG% by seconds left on the shotclock")+
        scale_y_continuous(labels=percent,limits = c(0,0.75))+
        blank_theme
      print(line)
    }
    if(input$plot==3){
      #create a line plot for FG% by the range from the closest defender(shot<10 feet)
      subset<-filter(shotdashboard,PLAYER_NAME%in%input$player&CLASS%in%"ClosestDefenderShooting")
      distance<-subset$SHOT_TYPE
      FG<-subset$FG_PCT
      line<-ggplot(subset,aes(x=distance,y=FG))+
        geom_point(color="#F8766D",size=3)+
        geom_line(aes(group=1),color="#F8766D",size=1)+
        ggtitle("FG% by feets away from the closest defender(Shot<10 feet)")+
        scale_y_continuous(labels=percent,limits = c(0,0.75))+
        blank_theme
      print(line)
    }
    if(input$plot==4){
      subset<-filter(shotchart,PLAYER_NAME%in%input$player)
      #summarize two pointers attempeted for each game
      df2<-subset%>%
        group_by(GAME_ID)%>%
        filter(SHOT_TYPE%in%"2PT Field Goal")%>%
        summarise("attempted2"=n())
      #summarize three pointers attempeted for each game
      df3<-subset%>%
        group_by(GAME_ID)%>%
        filter(SHOT_TYPE%in%"3PT Field Goal")%>%
        summarise("attempted3"=n())
      #combine the two created stats in a new dataframe
      df<-merge(x=df2,y=df3,by.x="GAME_ID",all=TRUE)
      #some NA's are produced because of no three pointers in that game, replace the NA's with 0
      df$attempted3[is.na(df$attempted3)]<-0
      
      #plot the boxplot by attempted shot types
      df<-df%>%gather(key=shot.type,value=shot.attempted,-GAME_ID)
      box<-ggplot(df,aes(x=shot.type,y=shot.attempted))+
        geom_boxplot(aes(color=shot.type))+
        ggtitle("Number of attempted two pointers and three pointers each game")+
        blank_theme+
        theme(legend.position = "none")
      print(box)
    }  
    if(input$plot==5){
      #plot the line plot of FG% by minutes remained in any quarter
      subset<-filter(shotchart,PLAYER_NAME%in%input$player)
      df<-subset%>%
        group_by(MINUTES_REMAINING)%>%
        summarise("accuracy"=sum(SHOT_MADE_FLAG)/sum(SHOT_ATTEMPTED_FLAG))
      minutesleft<-factor(df$MINUTES_REMAINING,levels = sort(unique(df$MINUTES_REMAINING),decreasing=TRUE))
      line<-ggplot(df,aes(x=minutesleft,y=accuracy))+
        geom_point(color="#F8766D",size=3)+
        geom_line(aes(group=1),color="#F8766D",size=1)+
        ggtitle("FG% by minutes remained in a quarter")+
        scale_y_continuous(labels=percent,limits = c(0,0.75))+
        blank_theme
      print(line)
    }
    if(input$plot==6){
      
      #Follow the guides from https://thedatagame.com.au/2015/09/27/how-to-create-nba-shot-charts-in-r/ to create an overlayed court image
      courtimgurl<-"https://thedatagame.files.wordpress.com/2016/03/nba_court.jpg"
      court <- rasterGrob(readJPEG(getURLContent(courtimgurl)),width=unit(1,"npc"), height=unit(1,"npc")) #court is the background picture
      #plot the shots on the court image by location coordinates
      subset<-filter(shotchart,PLAYER_NAME%in%input$player)
      chart<-ggplot(subset, aes(x=LOC_X, y=LOC_Y)) + 
        annotation_custom(court, -250, 250, -50, 420) +
        geom_point(color = "#FFA500",size=2,alpha=0.6)+
        xlim(-250, 250)+
        ylim(-50, 420)+
        ggtitle("Shot chart by shots location")+
        blank_theme+
        theme(axis.text.x = element_blank(), axis.text.y = element_blank())
      print(chart)
    }
    if(input$plot==7){
      #plot the FG% and number of shot attemps by each shooting region for average of the league
      courtimgurl<-"https://thedatagame.files.wordpress.com/2016/03/nba_court.jpg"
      court <- rasterGrob(readJPEG(getURLContent(courtimgurl)),width=unit(1,"npc"), height=unit(1,"npc"))
      region<-ggplot(averageleague, aes(x=LOCX, y=LOCY)) + 
        annotation_custom(court, -250, 250, -50, 420) +
        geom_point(aes(size=FGA),shape=19,color="grey",alpha=0.8)+
        geom_text(aes(label=FG_PCT),vjust=-0.9,size=3,color="orange")+
        xlim(-250, 250)+
        ylim(-50, 420)+
        ggtitle("Overall league FG% by region(size by shots attempted)")+
        blank_theme+
        theme(axis.text.x = element_blank(), axis.text.y = element_blank(),legend.position="bottom")
      print(region)
    }  
  })
  
  output$plot2 <- renderPlot({
    if(input$plot==1){
      subset<-filter(shotdashboard,PLAYER_NAME%in%input$player&CLASS%in%"GeneralShooting")
      type<-subset$SHOT_TYPE
      FG<-subset$FG_PCT
      #plot the bar plot
      bar<-ggplot(subset,aes(x=type,y=FG))+
        geom_bar(stat="identity",aes(fill=type))+
        xlab("Shot type")+ylab("Field goal percentage")+
        ggtitle("FG% by shot types")+
        scale_y_continuous(labels=percent)+
        blank_theme+
        theme(legend.position = "bottom")
      print(bar)
    }
    if(input$plot==2){
      #create a line plot for 2 point FG% by shotclock time left
      subset<-filter(shotdashboard,PLAYER_NAME%in%input$player&CLASS%in%"ShotClockShooting")
      subset<-subset[1:6,]
      timeleft<-subset$SHOT_TYPE
      FG3<-subset$FG3_PCT
      #reorder the "timeleft" variable
      timeleft<-factor(timeleft,levels = c("22-24","18-22","15-18","07-15","04-07","00-04"))
      line<-ggplot(subset,aes(x=timeleft,y=FG3))+
        geom_point(color="#619CFF",size=3)+
        geom_line(aes(group=1),color="#619CFF",size=1)+
        ggtitle("3 points FG% by seconds left on the shotclock")+
        scale_y_continuous(labels=percent,limits = c(0,0.75))+
        blank_theme
      print(line)
    }  
    if(input$plot==3){
      #create a line plot for FG% by the range from the closest defender(shot>10 feet)
      subset<-filter(shotdashboard,PLAYER_NAME%in%input$player&CLASS%in%"ClosestDefender10ftPlusShooting")
      distance<-subset$SHOT_TYPE
      FG<-subset$FG_PCT
      line<-ggplot(subset,aes(x=distance,y=FG))+
        geom_point(color="#00BFC4",size=3)+
        geom_line(aes(group=1),color="#00BFC4",size=1)+
        ggtitle("FG% by feets away from the closest defender(Shot>10 feet)")+
        scale_y_continuous(labels=percent,limits = c(0,0.75))+
        blank_theme
      print(line)
    }
    if(input$plot==4){
      #create a stacked bar with the proportion and accuracy of 2 pointers and 3 pointers
      subset<-filter(shotdashboard,PLAYER_NAME%in%input$player&CLASS%in%"Overall")
      prop2<-subset$FG2A_FREQUENCY
      prop3<-subset$FG3A_FREQUENCY
      accuracy2<-subset$FG2_PCT
      accuracy3<-subset$FG3_PCT
      df<-data.frame(
        status=c("made","miss","made","miss"),
        shottype=c("2pt","2pt","3pt","3pt"),
        accuracy=c(prop2*accuracy2,prop2*(1-accuracy2),prop3*accuracy3,prop3*(1-accuracy3))
      )
      df$status<-factor(df$status,levels = c("miss","made"))
      stackedbar<-ggplot(df,aes(x=shottype,y=accuracy,fill=status))+
        geom_bar(stat="identity")+
        ggtitle("Proportion and FG% of 2pt and 3pt shots")+
        scale_y_continuous(labels=percent,limits = c(0,0.75))+
        blank_theme+
        theme(legend.position = "bottom")
      print(stackedbar)
    }
    if(input$plot==5){
      #create line plot of FG% by periods
      subset<-filter(shotchart,PLAYER_NAME%in%input$player)
      df<-subset%>%
        group_by(PERIOD)%>%
        summarise("accuracy"=sum(SHOT_MADE_FLAG)/sum(SHOT_ATTEMPTED_FLAG))
      df$PERIOD<-as.factor(df$PERIOD)
      
      line<-ggplot(df,aes(x=PERIOD,y=accuracy))+
        geom_point(color="#C77CFF",size=3)+
        geom_line(aes(group=1),color="#C77CFF",size=1)+
        ggtitle("FG% by periods(5th and 6th period are OT)")+
        scale_y_continuous(labels=percent,limits = c(0,0.75))+
        blank_theme
      print(line)
    }
    if(input$plot==6){
      
      #Follow the guides from https://thedatagame.com.au/2015/09/27/how-to-create-nba-shot-charts-in-r/ to create an overlayed court image
      courtimgurl<-"https://thedatagame.files.wordpress.com/2016/03/nba_court.jpg"
      court <- rasterGrob(readJPEG(getURLContent(courtimgurl)),width=unit(1,"npc"), height=unit(1,"npc")) #background image
      #plot the location of shots on the court image
      subset<-filter(shotchart,PLAYER_NAME%in%input$player)
      chart<-ggplot(subset, aes(x=LOC_X, y=LOC_Y)) + 
        annotation_custom(court, -250, 250, -50, 420) +
        geom_point(aes(color = EVENT_TYPE),size=2,alpha=0.6)+#color by made or miss
        scale_color_manual(values = c("#008000", "#FF6347"))+
        xlim(-250, 250)+
        ylim(-50, 420)+
        ggtitle("Shot chart by made and miss")+
        blank_theme+
        theme(axis.text.x = element_blank(), axis.text.y = element_blank(),legend.position="bottom",legend.title = element_blank())
      print(chart)
    }
    if(input$plot==7){
      courtimgurl<-"https://thedatagame.files.wordpress.com/2016/03/nba_court.jpg"
      court <- rasterGrob(readJPEG(getURLContent(courtimgurl)),width=unit(1,"npc"), height=unit(1,"npc"))
      subset<-filter(shotchart,PLAYER_NAME%in%input$player)
      
      #group by shot regions(eliminate back court shots) and calculate the shots attempted and accuracy
      df<-subset%>%group_by(SHOT_ZONE_BASIC,SHOT_ZONE_AREA,SHOT_ZONE_RANGE)%>%summarise(FGA=sum(SHOT_ATTEMPTED_FLAG),Accuracy=sum(SHOT_MADE_FLAG)/sum(SHOT_ATTEMPTED_FLAG))
      "%ni%" <- Negate("%in%")   #create a new operator, which is the opposite of %in%
      df<-filter(df,SHOT_ZONE_AREA%ni%"Back Court(BC)")
      
      #set the coordinate as the average of all shots from particular region
      df$LOCX<-all$LOCX
      df$LOCY<-all$LOCY
      df$Accuracy<-percent(round(df$Accuracy,digits=3)) #turn accuracy into percentage
      
      region<-ggplot(df, aes(x=LOCX, y=LOCY)) + 
        annotation_custom(court, -250, 250, -50, 420) +
        geom_point(aes(size=FGA,color=ifelse(df$Accuracy>=averageleague$FG_PCT,"A","B")),shape=19,alpha=0.6)+
        geom_text(aes(label=Accuracy,color=ifelse(df$Accuracy>=averageleague$FG_PCT,"A","B")),vjust=-0.9,size=3)+
        xlim(-250, 250)+
        ylim(-50, 420)+
        ggtitle("Player's FG% by region(size by shots attempted)")+
        scale_color_manual(labels = c("above average", "below average"), values = c("#008000","#FF6347")) +
        blank_theme+
        theme(axis.text.x = element_blank(), axis.text.y = element_blank(),legend.position="bottom",legend.title = element_blank())
      print(region)
    }
  })

}