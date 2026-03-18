#!/usr/bin/env Rscript
##
## Basic R code to read the CSV file and show some
## simple counts of the data values.
##
## VERSION HISTORY
## [2024-10-13 MeD] Initial version
## [2025-10-17 MeD] Updated for the new data upload
## [2026-03-17 MeD] Automate selection of latest CSV file for running
##
##**********************************************************************
library(AnalysisHeader)

## Which file are we reading?
# inFile <- 'Cox-Lab-Serology_QIV-1-2-3_Updated_2025-03-31_20260209.csv'
inFile <- sort(list.files(pattern='Cox-Lab-.*\\.csv'), decreasing=TRUE)[1]

## Collect the run-time information
runInfo <- collectRunInfo(programName='basic-reader.R', version='1.2')
print(runInfo)
cat("Input file:", inFile, "\n\n")

## Read the dataset
cat("Reading input file:", inFile, "\n")
d <- read.csv(inFile, header=TRUE, as.is=TRUE)

## How big is it?
cat("\nHow big is the dataset?\n")
cat("\tSize in memory is", object.size(d), "bytes.\n",
    "\tas", nrow(d), "rows x", ncol(d), "columns.\n")

## What does it look like?
cat("\nAn excerpt of the data:\n")
print(head(d))

## Display the distribution of values in the dataset
cat("\nHow many values for each trial?\n")
print(table(d$Trial, useNA='ifany'))

cat("\nHow many different assays?\n")
print(table(SubAssay=d$SubAssay, Assay=d$Assay, useNA='ifany'))

cat("\nHow many values use each strain in each trial?\n")
print(table(d$Strain, d$Trial, useNA='ifany'))

cat("\nHow many values use each 'Day' in each trial?\n")
print(table(d$Day, d$Trial, useNA='ifany'))

cat("\nCompleted.\n")
