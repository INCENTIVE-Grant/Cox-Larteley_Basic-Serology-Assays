#!/usr/bin/env Rscript
##
## Basic R code to read the CSV file and show some
## simple plots
##
## VERSION HISTORY
## [2024-12-03 MeD] Initial version
## [2025-10-17 MeD] Updated for new dataset and new CSV file.
##
##**********************************************************************
library(lattice)
library(AnalysisHeader)
source('Controlled-Vocab.R')

## Which file are we reading?
inFile <- 'Cox-Lab-Serology_QIV-1-2-3_Updated_2025-03-31_20260209.csv'

## Collect the run-time information
runInfo <- collectRunInfo(programName='basic-reader.R', version='1.1')
print(runInfo)
cat("Vocabulary Version:", VocabVersion, "\n")
cat("Input file:", inFile, "\n\n")

## Read the dataset
cat("Reading input file:", inFile, "\n")
d <- read.csv(inFile, header=TRUE, as.is=TRUE)

## How big is it?
cat("\nHow big is the dataset?\n")
cat("\tSize in memory is", object.size(d), "bytes.\n",
    "\tas", nrow(d), "rows x", ncol(d), "columns.\n")

## What does it look like?
cat("\nAn excerpt of the data looks like:\n")
print(head(d))

## Show the QIV1 data distribution
print(bwplot(Value ~ Day|Strain, data=d,
             subset=(Trial == 'QIV1') & (Day %in% c('D000', 'D028')) &
                 (Assay == 'HI') & (Strain %in% VaxStrains$Strain),
             scale=list(y=list(log=TRUE)),
             main='QIV1: Dist. of titer pre- & post-vaccination, HI assay'
             )
      )

## Show how the QIV1 data is at Day-0 and Day-28
inx <- (d$Trial == 'QIV1') & (d$Assay == 'HI') &
    (d$Strain %in% VaxStrains$Strain) & (d$Day %in% c('D000', 'D028'))
d1 <- d[ inx, ]
print(densityplot(~Value|Strain, data=d1,
                  group=Day,
                  plot.points='rug',
                  auto.key=TRUE,
                  scale=list(x=list(log=TRUE)),
                  main='QIV1: Dist. titers, pre- & post-vac, HI assay'
                  ))

cat("\nCompleted.\n")
