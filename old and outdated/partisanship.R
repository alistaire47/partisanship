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
## Packages used include: xlsx, foreign, ggplot2, gridExtra (and dependencies).

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

## Function to change party code variable to factor of letter abbreviation
uncodeParty <- function(branch){
    pty <- c()
    for (p in branch$party) {
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
senate$party <- uncodeParty(senate)
house$party <- uncodeParty(house)

## Plotting function for single violin plot
library('ggplot2')
plotit <- function(data, houseLabel, congressNumber){
    qplot(
        party, d1, data=subset(data, congress==congressNumber), 
        geom='violin', 
        ylim=c(-1,1), ylab='Partisan Score', 
        xlab='Party', main=paste(houseLabel, congressNumber), 
        color=party, fill=party
    ) + scale_fill_brewer(type='qual', palette=6) +
    scale_color_brewer(type='qual', palette=6) +
    guides(fill=FALSE, color=FALSE) +
    theme(plot.title=element_text(size=18, vjust=1))
}

## Make a file to contain plots images and set working directory to that file
dir.create(file.path('./PartisanshipAnimation'))
setwd(file.path('./PartisanshipAnimation'))

## Make and save image of plot for each congress
library('gridExtra')
for(i in 1:length(unique(senate$congress))){
    ## Creates a name for each plot file with leading zeros
    if (i < 10) {name <- paste('000',i,'plot.png',sep='')}
    if (i < 100 && i >= 10) {name <- paste('00',i,'plot.png', sep='')}
    if (i >= 100) {name <- paste('0', i,'plot.png', sep='')}
    
    ## Makes and combines Senate and House plots, and saves combined plot as a 
    ## .png file in the working directory
    png(name)
    grid.arrange(plotit(senate, "Senate", i), plotit(house, "House", i), ncol=2)
    dev.off()
}


