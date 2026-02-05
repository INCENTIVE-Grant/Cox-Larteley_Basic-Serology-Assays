#!/usr/bin/env Rscript
##
## Quick-n-dirty script to read the previous uploaded data (CSV) and compare the
## data with the current CSV file.
##
## VERSION HISTORY
## [2026-01-24 MeD] Initial version
## [2026-02-04 MeD] Update filenames
##
##********************************************************************************
## Libraries
library(AnalysisHeader)

## Load the standard names for things
source('Controlled-Vocab.R')

## Program Name and Version
ProgramName <- 'compareWithPrevious.R'
Version <- 'v2.1'

options(warn=1)

## GLOBAL Variables
oldFile <- '../2024-07-18_Zenodo-Upload-Becky-Cox/Incentive_QIV1_2_3-HI_Final_v1.0_2024-09-09.csv'
newFile <- 'Cox-Lab-Serology_QIV-1-2-3_Updated_2025-03-31_20260204.csv'

## Prepare output files: logging and plots
today <-  format(Sys.time(), "_%Y%m%d")
rootName <- paste0(gsub('\\..*$', '', ProgramName), today)
pltName <- paste0(rootName, '.pdf')
logName <- paste0(rootName, '.log')

## Set up the processing based on if we're interactive or a script
if( interactive() ) {
    par(ask=TRUE)   # slow down the plots
} else {
    ## Set up logging
    cat("\n*** Redirecting program reporting to Log File:", logName, "\n")
    LogFile <- file(logName, open='wt')
    sink(LogFile)
    sink(LogFile, type='message')

    ## Set up plotting
    pdf(file=pltName, width=10, height=8, paper='USr', pointsize=10)
}

## Record the run information
print(collectRunInfo(programName=ProgramName, version=Version))
cat('Vocabulary Version:', VocabVersion, "\n\n")
cat("Data input & output files:\n",
    "\tOld = ", oldFile, "\n",
    "\tNew = ", newFile, "\n",
    "\n",
    "\tPlot = ", pltName, "\n",
    "\tLog  = ", logName, "\n",
    "\n",
    sep='')

##********************************************************************************
##                         SUBROUTINES
##********************************************************************************
#' myEquals - an "equal" similar to "identical()" that looks for NA to match NA.
#'
#' @param x is a numeric or character vector that is to be compared
#' @param y is a vector to match 'x' in type, value and NA location
#' @return a logical vector of TRUE where the values match and FALSE where they don't.
myEquals <- function(x, y) {
    stopifnot(typeof(x) == typeof(y), length(x) == length(y),
              typeof(x) %in% c("logical", "integer", "double", "character"),
              typeof(x) %in% c("logical", "integer", "double", "character"))
    result <- rep(NA, length(x))
    ## Note: !is.finite() includes: NA, NaN, +Inf, -Inf. I am ignoring this.
    inxNAx <- !is.finite(x)
    inxNAy <- !is.finite(y)
    inxNAok <- inxNAx & inxNAy
    inxNAbad <- inxNAx != inxNAy
    inxOk  <- is.finite(x) & is.finite(y)
    result[inxOk] <- x[inxOk] == y[inxOk]
    result[inxNAok] <- TRUE
    result[inxNAbad] <- FALSE
    stopifnot(is.finite(result))
    return(result)
}

##********************************************************************************

## Load the datasets
old <- read.csv(oldFile, header=TRUE, as.is=TRUE)
new <- read.csv(newFile, header=TRUE, as.is=TRUE)

## Strains no longer match as we've removed the leading zero. Update Old material.
## First check that we recognize ALL strains
allStrains <- unique(c(KnownStrains, AliasStrains$Alias))
stopifnot(old$Strain %in% allStrains)
inx <- match(old$Strain, AliasStrains$Alias)
## Annotate the changes before make them
delta <- sort(unique(inx[!is.na(inx)]))
cat("\nReplacing old strain name with new strain name:\n")
print(AliasStrains[delta,])
## Make the changes
old$Strain[ !is.na(inx) ] <- AliasStrains$Canonical[ inx[!is.na(inx)] ]
stopifnot(old$Strain %in% KnownStrains)

## Confirm that the old dataset is limited
cat("\nOld data set contents:\n")
print(table(old$Trial, old$Assay))
cat("\nNew data set contents:\n")
print(table(new$Trial, new$Assay))
cat("\n")

## Why twice as many points in the old HI vs new HI set?
inx <- old$Assay == 'HI' & old$Trial == 'QIV1'
cat("Old values for HI:\n")
print(table(old$Day[inx]))
inx <- new$Assay == 'HI' & new$Trial == 'QIV1'
cat("New values for HI:\n")
print(table(new$Day[inx]))

## Compare HI Day 0 and Day 28
par(mfrow=c(2,2))
for(trial in c('QIV1', 'QIV2', 'QIV3')) {
    for(day in c('D000', 'D003-8', 'D028', 'D030', 'D058')) {
        inxOld <- old$Trial == trial & old$Assay == 'HI' & old$Day == day
        inxNew <- new$Trial == trial & new$Assay == 'HI' & new$Day == day
        if(sum(inxOld) == 0 & sum(inxNew) == 0) {
            cat(sprintf('Trial: %s and Day: %s have no values.\n', trial, day))
            next
        }

        ## QIV3 reports different subjects - sort this out
        if(sum(inxOld) != sum(inxNew)) {
            notInOld <- setdiff(new$SubjectID[inxNew], old$SubjectID[inxOld])
            notInNew <- setdiff(old$SubjectID[inxOld], new$SubjectID[inxNew])
            stopifnot(length(notInOld) == 0)  # I have seen data dropped between old and new
            cat("\nSeveral subjects are missing in the new dataset for Trial,",
                trial, ", Day,", day, ", shown below:\n")
            inx <- inxOld & (old$SubjectID %in% notInNew)
            print(old[inx, ])
            inxOld <- inxOld & !(old$SubjectID %in% notInNew)
        }

        ## Extract and display the differences, if any, between the data sets
        for(i in 1:nrow(VaxStrains)) {
            strain <- VaxStrains$Strain[i]
            inxO <- inxOld & old$Strain == strain
            inxN <- inxNew & new$Strain == strain
            stopifnot(sum(inxO) == sum(inxN), old$SubjectID[inxO] == new$SubjectID[inxN])
            o <- log10(old$Value[inxO])
            n <- log10(new$Value[inxN])
            a <- (o + n)/2
            m <- n - o
            plot((o+n)/2, n-o, main=sprintf('%s: %s %s', trial, day, strain))
            abline(h=0, col='SkyBlue')

            ## Draw a rug where missing values occur in one but not the other
            inxNA <- is.na(o) & !is.na(n)
            rug(n[inxNA], col='red')
            inxNA <- !is.na(o) & is.na(n)
            rug(o[inxNA], col='blue')

            ## Perform a numerical comparison, including checking the NA matches NA
            inx <- myEquals(old$Value[inxO], new$Value[inxN])
            if(any(inx != TRUE) ) {
                cat('Not all values are equal: Trial,', trial, ', Day,', day, ', Strain,', strain, "\n")
                print(cbind(old[inxO, ], NewValue=new[inxN, 'Value'])[!inx,])
            }
        }
    }
}

##********************************************************************************
## Close things
if( !interactive() ) {
    ## Close the plot
    err <- dev.off()

    ## Log the finish
    endTime <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    cat("\nCompleted run:", endTime, "\n")

    ## Close the log file
    sink(type='message')
    sink()

}

cat("\nCompleted.\n")
