#!/usr/bin/env Rscript
##
## Compare the Reponder data across versions of the data.
##
## VERSION HISTORY
## [2026-03-15 MeD] Initial version
##
##********************************************************************************
library(AnalysisHeader)

## GLOBAL Variables
PROGRAM <- 'compareResponder.R'
VERSION <- 'v1.0'
runInfo <- collectRunInfo(program=PROGRAM, version=VERSION)

## Where are the old values located (on Zenodo, I know ...)
oldDir <- '../2024-05-10_Responder-Non-Responder_v6.1/Cox-Larteley_Resp-Non-Resp_2024-06-14'
newDir <- '.'

## Old files and new files to compare
oldFiles <- c("QIV1-Responder.csv","QIV2-Responder.csv", "QIV3-Responder.csv")
newFiles <- c("Responder-QIV1_20260317.csv", "Responder-QIV2_20260317.csv", "Responder-QIV3_20260317.csv")

## Set up logging
Today <- format(Sys.time(), "%Y%m%d")
logName <- paste0(gsub('\\.R', '', PROGRAM), '_', Today, '.log')

## Open log file if run in batch mode (non-interactive).
if( !interactive() ) {
    cat("*** Writing all output to log file:", logName, "\n")
    logFile <- file(logName, open='wt')
    sink(logFile)
    sink(logFile, type='message')
}

print(runInfo)

cat("For this comparison, we compare data extracted from the Excel sheet",
    "circulated to INCENTIVE WP5 on 2024-06-14 containing Responder/Non-Responder",
    "data. The Excel file was named:",
    "   Incentive_EU_QIV1-2-3_responder-nonresponder_HI_2024-06-14.xlsx.",
    "\nThe data in the 'old' files was extracted from this Excel file.",
    "\nThe data for the 'new' files was extracted from the Excel file named:",
    "   Incentive_QIV1_2_3_ELISA_HI_MN_and_ELLA_Data_updated_2025-03-31.xlsx,",
    "and converted to Responder/Non-Responder values following the method in the",
    "old Excel file.",
    " ",
    sep="\n")

cat("Files:\n",
    "\tOld data files:\n",
    "\t\t", paste(file.path(oldDir, oldFiles), collapse='\n\t\t'), "\n",
    "\tNew data files:\n",
    "\t\t", paste(file.path(newDir, newFiles), collapse='\n\t\t'), "\n",
    sep='')

cat("\tLog data file:\n\t\t", logName, "\n")

cat("\n", paste(rep('*', getOption('width')-3), collapse=''), "\n", sep='')

##********************************************************************************
## Read in the old data
oldDat <- list()
for(i in 1:3) {
    oldDat[[i]] <- read.csv(file.path(oldDir, oldFiles[i]), header=TRUE, as.is=TRUE)
}

## Read in the new data
newDat <- list()
for(i in 1:3) {
    newDat[[i]] <- read.csv(file.path(newDir, newFiles[i]), header=TRUE, as.is=TRUE)
}

## Conform all headers within Old and New correspond
for(i in 2:3) {
    stopifnot( colnames(oldDat[[1]]) == colnames(oldDat[[i]]) )
    stopifnot( colnames(newDat[[1]]) == colnames(newDat[[i]]) )
}

## Remap the column names: Old --> New
##    SubjectID --> SubjectID
##    BL        --> PreVac
##    PostVac   --> PostVac
##    FC        --> FC
##    RE2.5     --> Resp
oldNames <- colnames(oldDat[[1]])
oldNames <- gsub('^BL\\.', 'PreVac.', oldNames)
oldNames <- gsub('RE2.5', 'Resp', oldNames)
## Confirm that all of the colnames(newDat) are found in the updated "oldNames"
inx <- match(colnames(newDat[[1]]), oldNames)
stopifnot( !is.na(inx) )

## Rebuild the oldDat to match the newDat structure
for(i in 1:3) {
    oldDat[[i]] <- oldDat[[i]][ , inx]
    colnames(oldDat[[i]]) <- oldNames[inx]
}

## That's all nice BUT oldDat$Resp is NOT newDat$Resp.
## In oldDat there is no combination of PostVac >= 40. The Resp is ONLY FC >= 2.5.
## Fix that.
oN <- oldNames[inx]
inxPV   <- grep('^PostVac', oN)
inxFC   <- grep('^FC', oN)
inxResp <- grep('^Resp', oN)
stopifnot(length(inxPV) == length(inxFC), length(inxPV) == length(inxResp))
for(i in 1:3) {
    ## Note: QIV3 "new" has fewer subject that QIV3 "old". Drop the extras
    ind <- oldDat[[i]]$SubjectID %in% newDat[[i]]$SubjectID
    if(any(ind == FALSE)) {
        cat("Subjects missing in New Data:\n\t",
            paste(oldDat[[i]]$SubjectID[ind==FALSE], collapse=', '), "\n",
            "Dropping those subjects in comparison.\n", sep='')
        oldDat[[i]] <- oldDat[[i]][ind,]
    }
    for(j in 1:length(inxPV)) {
        oldDat[[i]][, inxResp[j]] <- (oldDat[[i]][, inxPV[j] ] >= 40) & (oldDat[[i]][, inxFC[j] ] >= 2.5)
    }
}

## Confirm that OldDat == NewDat (QIV1 = yes, QIV2 = no, QIV3 = NA) WTF?!
cat("\nComparing dataset, old and new, ignoring NA:\n")
for(i in 1:3) {
    cat(sprintf("\tAll of QIV%d, old and new, are identical: %s\n", i,
                all(oldDat[[i]] == newDat[[i]], na.rm=TRUE))
        )
}

cat("\nComparing dataset, old and new, noting NA:\n")
for(i in 1:3) {
    cat(sprintf("\tAll of QIV%d, old and new, are identical: %s\n", i,
                all(oldDat[[i]] == newDat[[i]], na.rm=FALSE))
        )
}

## Figure out where QIV3 differs, old vs new
inx <- which(is.na(oldDat[[3]]) != is.na(newDat[[i]]), arr.ind=TRUE)
cat("\nQIV3 dataset, old vs new, differs by an NA at these coordinates:\n")
print(inx)

## Manual, I see row 14: col 16:17 which is data re: Washington strain
cat("\nOld (columns 1 and 14-17):\n\t")
print(oldDat[[3]][14, c(1,14:17) ])
cat("\nNew:\n\t")
print(newDat[[3]][14, c(1,14:17) ])
cat("\n")

## Found the Issue!
cat("Issue located manually.\n")
cat("Issue found in Excel sheet, 'QIV3-CHU HI', cell P22. This is empty for 'no value'.\n")
cat("Excel interprets an empty cell as '0' so the calculation in Q22 yeilds '0'. This then\n")
cat("carries on to cell R22 interpreted as a 'non-responder' where it is in fact a 'unknown value'.\n")
cat("\nIn summary, subject CHU-017 is not a 'non-responder' but rather an 'unknown'.\n")
cat("The error is with Excel interpreting an empty cell as '0'.\n\n")

##********************************************************************************
## Close and cleanup
if( !interactive() ){
    cat("Completed:", format(Sys.time()), "\n")

    sink(type='message')
    sink()
}
cat("Completed\n")
