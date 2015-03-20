#!/usr/bin/R
##
## An R script to build an animation of partisanship in Congress using 
## DW-NOMINATE scores from Poole and Rosenthal's Voteview Blog
## (http://www.voteview.com/dwnominate.asp). Senate data is "Senator Estimates 
## 1st to 113th Senates (Excel File, 9,062 lines)", and House data is "Legislator
## Estimates 1st to 113th Houses (Stata 12 File, 37,517 lines)". Formats are 
## different because of website dysfuntion. Script assumes data files are named 
## "senate.xlsx" and "house.dta" and are saved in the working directory from  
## which the script is run.
##
## R packages are loaded as necessary, to make outside function sources obvious.
## Packages used include: xlsx, foreign, ggplot2 (and dependencies).
##
## Fonts used for plotting include: Trade Gothic Bold No. 2
##
## Converting plots to an animated .gif requires the ImageMagick command line
## application (http://www.imagemagick.org).

## Make a list of classes with which to read in data
classes <- rep('double', 16)
classes[5] <- 'character'
classes[7] <- 'character'

## Read in data
library(xlsx)
library(foreign)
senate <- read.xlsx2('senate.xlsx', 1, header=FALSE, colClasses=classes)
house <- read.dta('house.dta')
names <- c('congress', 'icpsrID', 'stateCode', 'district', 'state', 'party', 'name', 'd1', 'd2', 'd1err', 'd2err', 'd1d2corr', 'logLikelihood', 'numVotes', 'numClsfnErr', 'geoMeanProb')
names(senate) <- names
names(house) <- names
senate$side <- 'Senate'
house$side <- 'House'
capitol <- rbind(senate, house)

## Function to change party code variable to factor of letter abbreviation
uncodeParty <- function(data){
    pty <- c()
    for (p in data$party) {
        if (p == 100){
            pty <- append(pty, 'D')
        } else if (p==200) {
            pty <- append(pty, 'R')
        } else {
            pty <- append(pty, 'I')
        }
    }
    factor(pty, levels=c('R', 'D', 'I'))
}
capitol$party <- uncodeParty(capitol)

## Factorize 'side'
capitol$side <- factor(capitol$side, levels=c('Senate', 'House'))

## Plotting function for comparative violin plot
library('ggplot2')
cols <- c('D'='#1f78b4', 'R'='#e41a1c', 'I'='#762a83')
plotit <- function(data, congressNumber){
    qplot(
        party, d1, data=subset(data, congress==congressNumber), 
        geom='violin', 
        ylim=c(-1,1), ylab='Partisanship Score',
        xlim=c('I', 'D', 'R'), xlab='Party', 
        main=paste('Congress', congressNumber), 
        color=party, fill=party
    ) + coord_flip() +
    scale_fill_manual(values=cols) +
    scale_color_manual(values=cols) +
    guides(fill=FALSE, color=FALSE) +
    theme(text=element_text(family='Trade Gothic Bold No. 2'),
          plot.title=element_text(hjust=0, vjust=0.6),
          axis.title=element_text(size=10, hjust=0),
          axis.title.y=element_text(vjust=-1),
          strip.text=element_text(hjust=0.05, color='white'),
          panel.background=element_rect(fill='#a6cee3', color='white'),
          strip.background=element_rect(fill='#1f78b4', color='white')) + 
    facet_grid(. ~ side)
}

## Make a file to contain plots images and set working directory to that file
dir.create(file.path('./PartisanshipAnimation'))
setwd(file.path('./PartisanshipAnimation'))

## Make and save image of plot for each congress
for(i in 1:113){
    ## Creates a name for each plot file with leading zeros
    if (i < 10) {name <- paste('000',i,'plot.png',sep='')}
    if (i < 100 && i >= 10) {name <- paste('00',i,'plot.png', sep='')}
    if (i >= 100) {name <- paste('0', i,'plot.png', sep='')}
    
    ## Makes and saves plot as a .png file in the working directory
    ggsave(filename=name, plot=plotit(capitol, i), 
           width=8, height=4, units='in', dpi=100)
}

## Use ImageMagick via a system command to combine .png files into an animated 
## .gif file.
system('convert *.png -delay 3 -loop 0 partisanship.gif')

setwd('..')
