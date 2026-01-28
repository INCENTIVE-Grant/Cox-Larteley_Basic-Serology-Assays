#!/usr/bin/env Rscript
##
## Simple program to read XLSX file of results from Rebecca Cox lab
## containing values from several assay types: HI, MN, ELISA, ELLA.
## These are the basic assays for the INCENTIVE Trial (EU Horizon
## Grant 2020).
##
## VERSION HISTORY
## [2023-06-26 MeD] Being parsing of results file. Learn to use "read_xlsx()".
## [2023-08-03 MeD] Lots of extra code using 'read_xlsx()'.
## [2023-09-25 MeD] Complete work on automatic parsing of column names.
## [2023-10-01 MeD] Disable the fixed input filename. Add a Log file and Analysis Header.
## [2023-10-05 MeD] Fix write.csv() option error; add formatting. Bump to v1.2.
## [2024-01-26 MeD] Copied from 2023-06-25_Parse-HI-to-CSV/parse-HI-to-CSV.R to work on
##                  new XLS file.
##                  Massive ugly hacks added to force ELISA sheets to confirm with earlier sheets.
##                  See functions: fix_QIV1_Elisa() and fix_QIV2_Elisa() for the hacks.
##                  Note: the fix_*_() functions are only called if particular errors are detected.
## [2024-02-19 MeD] Copied to /home/hvp/Documents/Projects/2024-02-19_Parse-HI-to-CSV_v4/ to begin
##                  work on Becky's latest delivery of data, named here as:
##                  INCENTIVE-HI-MN-ELLA-ELISA-Assays_2024-02-19.xlsx, though she originally
##                  named it: serology_results_Incentive_all_trials210623.xlsx.
##                  Added extensive set of routines to "patch" minor errors in raw data.
## [2024-02-22 MeD] Add new AssayType: 'MN-Plasma' as there are two QIV2 MN assays.
##                  Fix duplicated data found in QIV3-HI, column D58-3.
## [2024-04-11 MeD] Copied from 2024-02-19_Parse-HI-to-CSV_v4 and edited.
## [2024-07-20 MeD] *************************************************************************
## [2024-07-20 MeD] Radical format change for R.Cox *.xlsx file. Strip code down and re-write.
## [2024-09-09 MeD] Change to require command-line args; also permit "errors" to be absent in
##                  fix_*() functions. That is, if error is present, fix it. If not, ignore it.
## [2025-03-27 MeD] Alter the spellings of some virus strains:
##   "A/Darwin/09/2021 (H3N2)"                --> "A/Darwin/9/2021 (H3N2)"
##   "A/HongKong/4801/2014 (H3N2)"            --> "A/Hong Kong/4801/2014 (H3N2)"
##   "A/Singapore/IFNIMH-16-0019/2016 (H3N2)" --> "A/Singapore/INFIMH-16-0019/2016 (H3N2)"
## [2025-03-30 MeD] New dataset supplied (v8). Start the new code with
##                  this version of the old code.  Ugg! The new ELISA
##                  data has several different assays per page. Add a
##                  new LONG-format column to accomodate.
##                  Rename the code to parse-Cox-Serology-Data.R.
## [2025-10-13 MeD] Update to include the 'Controlled-Vocab.R' file.
##
##********************************************************************************
library(AnalysisHeader)
library(tibble)
library(readxl)

## GLOBAL variables
ProgramName <- 'parse-Cox-Serology-Data.R'
Version <- 'v1.9'

options(warn=1)

## Enable some DEBUGGING statements if TRUE
DEBUG <- FALSE

## Annotate that DEBUGGING is turned on
if(DEBUG == TRUE) {
    cat("\nDEBUGGING is Enabled.\n")
}

## Bring in many variables that are used across all parsing:
##    TrialNames, AssayNames, SubAssayNames, SubAssays,
##    SampleTypes, VisitDay (D000 - D365), CSV ColumnNames,
##    KnownStrains, AliasStrains, ExcelColumns.
source('Controlled-Vocab.R')

## Append fake strain names for the ELLA assay
KnownStrains <- c(KnownStrains, 'A/H6N2', 'A/H7N1', 'B/H6NB')

## Append fake strain names for the ELLA assay
tmpDF <- data.frame(Alias=c("N2", "N1", "B/NB", "NB"),
                    Canonical=c("A/H6N2", "A/H7N1", "B/H6NB", "B/H6NB")
                    )
AliasStrains <- rbind(AliasStrains, tmpDF)
stopifnot(AliasStrains$Canonical %in% KnownStrains)

## Translate "Visit Number" to "Day" in QIV2
VisitNumber <- data.frame(Visit=c('V1',   'V2',   'V3',   'V4',   'V5',   'V6'  ),
                          Day=  c('D0',   'D3',   'D30',  'D58',  'D180', 'D360'),
                          sDay= c('D000', 'D003', 'D030', 'D058', 'D180', 'D360'),
                          stringsAsFactors=FALSE)

## Known column names for values to store in LONG format
KnownColumnNames <- c('D0', 'D28', 'D3-8', 'D30', 'D58', 'D180', 'D360')

##**********************************************************************
## Begin MAIN code - process command line arguments.

## Assign my input file name; if I don't, then get the command-line argument
if(interactive())
    inFile <- "Incentive_QIV1_2_3_ELISA_HI_MN_and_ELLA_Data_updated_2025-03-31.xlsx"

## Check if an 'inFile' already exists. Useful in debugging, etc.
if( !exists('inFile') ) {
    inFile <- commandArgs(trailingOnly=TRUE)[1]
}

## Check command-line args are ok else display usage message
if(is.na(inFile) || file.exists(inFile) == FALSE) {
    cat(paste0(ProgramName, " - Rscript to convert Becky Cox's XLSX results to LONG-format CSV"),
        paste("Version:", Version),
        " ",
        "Usage:",
        paste0("\t", ProgramName, "<input-XLSX-file>"),
        "\nWhere:",
        "\t<input-XLSX-file> = An Excel file (*.xlsx) in Becky Cox's format for her assays",
        "\nOutputs",
        "\tOutput CSV file: same name as input with '.xlsx' replaced with '.csv'. No overwriting.",
        "\tLog text file: parse-Cox-Serology-Data_YYYYMMDD.log",
        " ",
        "NOTE: This code is highly customized for the XLSX file actually delivered. This is a failure.",
        " ",
        sep='\n')
    stop("Invalid input filename")
}

## Prepare an output file. Base the file name on the input name and on date.
today <- Sys.time()
outName <- gsub('\\.xlsx$', paste0(format(today, "_%Y%m%d"), '.csv'), inFile)
if((file.exists(outName)) && (DEBUG==FALSE)) {
    cat("Output file: '", outName, "' already exists. Exiting.\n", sep='')
    stop("File exists")
}

## Prepare a Log File for logging data via STDOUT & STDERR
logFileName <- paste0(ProgramName, '_', format(today, '%Y%m%d'), '.log')
if( !interactive() ) {
    cat("\n*** Redirecting program reporting to Log File:", logFileName, "\n")
    LogFile <- file(logFileName, open='wt')
    sink(LogFile)
    sink(LogFile, type='message')
}

print( collectRunInfo(ProgramName, Version) )
cat('Vocabulary Version:', VocabVersion, "\n\n")
cat("Data input & output files:\n",
    "\tInp = ", inFile, "\n",
    "\tOut = ", outName, "\n",
    "\tLog  = ", logFileName, "\n",
    "\n",
    sep='')


## Annotate that DEBUGGING is turned on (here, into the log file)
if(DEBUG == TRUE)
    cat("\nDEBUGGING is Enabled.\n")

##----------------------------------------------------------------------
## OVERVIEW of the parsing process.
##
## With the sheet names acquired and parsed, we could read each in and
## output a single CSV per sheet. But, what to do with "Strain" and
## "Day"?
##
## We should use a a LONG format.
##    https://www.statology.org/long-vs-wide-data/
##    https://libguides.princeton.edu/R-reshape
##
## What columns will we want? Follow the Excel data hierarchy:
##      SubjectID - Trial - Assay - Strain - Day (or Fraction, eg Day30/Day0) - Value
##
## Expected Values
##   SubjectID = as input, stripped of leading and trailing BLANKs
##   Trial = "QIV1", "QIV2", "QIV3" - See GLOBAL 'TrialNames'
##   Assay = "HI", "MN", "ELLA" - See GLOBAL 'AssayNames'
##   Strain = An enumerated set of names - See GLOBAL 'KnownStrains'
##   Day = "D00", "D03", "D28", ..., "Frac_D28_D0", etc
##   Value = numeric from Excel sheet
##
##********************************************************************************
##                                SUBROUTINES
##********************************************************************************
#' wrapText - utility to output long strings wrapped in a tidy manner
#'
#' I frequently output something similar to:
#'    cat("Header:\n\t", paste(vector, collapse=', '), "\n")
#' which is frequently too long to read easily as the terminal wraps the text. I
#' can improve this by wrapping with `strwrap()` which then requires an additional
#' paste(x, collapse='\n'). This function wraps all that wrapping. (Am I a 'wrap artist'?)
#'
#' @param v Character vector to be concatonated with COMMA and wrapped for output.
#' @param prefix Character to lead each wrapped line with. Default = '\t'
#' @return Long, wrapped character vector of length 1.
wrapText <- function(v, prefix='\t') {
    return(paste(strwrap(paste(v, collapse=', '), width=70, prefix=prefix, initial=prefix),
                 collapse='\n'))
}

#' myPMax - a replacement for the pmax() function that ignores NA values
#'
#' @param x - vector of values to compare
#' @param y - vector of values to compare
#' @return z - vector of pairwise 'max' results, ignoring NA if possible. Returns
#'    non-NA value or, if both x & y values are NA, then returns NA.
myPMax <- function(x, y) {
    stopifnot(is.numeric(x), is.numeric(y), length(x) == length(y))
    ## Initialize the variables
    result <- rep(NA_real_, length(x) )
    inxNAx <- is.na(x)
    inxNAy <- is.na(y)
    inxOk <- !inxNAx & !inxNAy

    ## Compute the max for where a pair exists
    result[inxOk] <- ifelse(x[inxOk] > y[inxOk], x[inxOk], y[inxOk])

    ## Compute the max for when a value is missing. If both are missing, pick the 'y' NA value.
    result[inxNAx] <- y[inxNAx]
    result[inxNAy] <- x[inxNAy]

    return(result)
}

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

##----------------------------------------------------------------------
#' parseSheetsNames - Convert vector of sheet names into data.frame, identifying results
#'
#' The sheet names from "excel_sheets" is an uncontrolled collection
#' of user supplied names for the sheets. Based on the existing names,
#' they are reasonably regular, but not perfect. We wish to know:
#' AssayType = {HI, MN, ELLA} and samples from which trial,
#' Trial={QIV1, QIV2, QIV3}. We'll use a RegEx to make this more
#' robust to format changes. (And we'll still probably fail). We test
#' for failures with "stopifnot()" clauses.
#'
#' @param sheetNames Vector of strings containing the names of the sheets in an Excel workbook
#' @return data.frame containing the Sheet Name and the extracted values for Trial & Assay
parseSheetNames <- function(sheetNames) {
    stopifnot(is.character(sheetNames), length(sheetNames) >= 1, any(is.na(sheetNames)) == FALSE)

    ## Check for which QIV we have. Be robust to zero, one, or many
    ## QIV (exactly "one" is required.)
    ##
    ## Note: grep returns an integer for the position in the vector
    ## containing the matched string.
    ##
    ## Note: This scheme is NOT robust to "QIV1" being a sub-string
    ## within another string.  Could fix this by padding "sheetNames"
    ## with a leading and trailing BLANKs, then search for the string,
    ## " QIV1 ", etc.
    trial <- list()
    for(v in TrialNames) {
        trial[[v]] <- grep(v, sheetNames)
    }
    ## Look for a sheet name that lists two trials
    stopifnot( any(duplicated(unlist(trial))) == FALSE )

    ## Check for which Assays we have. Use scheme similar to that for QIV.
    assay <- list()
    for(v in AssayNames) {
        assay[[v]] <- grep(v, sheetNames)
    }
    ## Any sheet names containing two assays?
    stopifnot( any(duplicated(unlist(assay))) == FALSE )

    ## Create an empty data.frame for the results
    tmp <- data.frame(SheetName=sheetNames,
                      Trial=factor(NA, levels=TrialNames),
                      Assay=factor(NA, levels=AssayNames),
                      stringsAsFactors=FALSE)

    ## Loop over the indexes from grep on 'trial'; name those via TrialNames[]
    for(i in seq_along(TrialNames)) {
        tmp$Trial[ trial[[i]] ] <- TrialNames[i]
    }

    ## And again for the assay; check against AssayNames[]
    for(i in seq_along(AssayNames)) {
        tmp$Assay[ assay[[i]] ] <- AssayNames[i]
    }

    ## Check for "Plasma" as used in QIV2 with MN assay. Convert Assay type
    plasma <- grepl('Plasma', sheetNames)
    stopifnot(tmp$Assay[plasma] == 'MN')
    tmp$Assay[plasma] <- 'MN-Plasma'

    ## Check for "Responder" as used in QIV2 for an extra sheet. Convert Assay Type.
    responder <- grepl('Responder', sheetNames)
    stopifnot(tmp$Assay[responder] == 'HI', tmp$Trial[responder] == 'QIV2')
    tmp$Assay[responder] <- 'HI-Responder'

    ## Check for missing values in sheetNames (i.e. anything not parsable?)
    stopifnot( all(is.na(tmp) == FALSE) )

    return(tmp)
}

#' Given a sheet name, extract contents to a long-fromat data.frame
#'
#' @param excelFile Filename of the Excel file that we're parsing
#' @param sheetName Name of the worksheet within the Excel file that we're parsing
#' @param trialName One of { QIV1, QIV2, QIV3 } - see GLOBAL 'TrialNames'
#' @param assayName One of { HI, MN, ELLA } - see GLOBAL 'AssayNames'
#' @return dataframe containing 'long-format' of data on sheet
parseSheet <- function(excelFile, sheetName, trialName, assayName) {
    stopifnot(trialName %in% TrialNames,
              assayName %in% AssayNames,
              is.character(excelFile), length(excelFile) == 1,
              is.character(sheetName), length(sheetName) == 1
              )
    if(DEBUG == TRUE)
        cat(sprintf("\n# parseSheet('%s', '%s', '%s', '%s')\n",
                    excelFile, sheetName, trialName, assayName))

    ## Collect the assays (sub-assays) from row one of the sheet
    subAssays <- parseAssayRow(excelFile, sheetName)

    ## NOTE: if there are multiple assays, then there can be different
    ## virus rows per sub-assay. That is, one assay will be run over
    ## just two different days, while a different sub-assay will be
    ## run over more days.  For an example, see sheet: QIV2-ELISA,
    ## where the NA-IgG assay is only 2 days but the HA-IgG assay is 4
    ## days.  This means that we need to process the "sub-assay" sheet
    ## as stand-alone assays.

    ## Collecting the second row which is "Strain Names".
    ## This returns a data.frame of the sub-tables positions and which strain it covers.
    subTables <- parseVirusRow(excelFile, sheetName)

    ## Collect a whole data.frame representing the WIDE data from row 3 onwards
    wholeSheet <- readDataSheet(excelFile, sheetName)

    ## Change the first column heading uniformly to "SubjectID".
    ## If it wasn't already similar to "SubjectID", print a warning about the change.
    if(grepl('^ *Subject *ID *$', colnames(wholeSheet)[1] ) == FALSE) {
        cat("\n*** Warning: Changing: '", colnames(wholeSheet)[1], "' --> 'SubjectID'.\n\n", sep='')
    }
    colnames(wholeSheet)[1] <- 'SubjectID'

    ##----------------------------------------------------------------------
    ## Prepare fixes, if required, for different sheets here
    ##
    if(sheetName == 'QIV2UIB HI') {
        wholeSheet <- fix_QIV2_HI(subTables, wholeSheet)
    }

    ##----------------------------------------------------------------------

    ## Create pseudo-sheets as subsets of columns based on subAssays, above.
    ## This is new code added with the release of the ELISA data, 2025-03-30.
    ## Note: Loop from row 2 as row 1 contains the fixed info: SubjectID, Trial, etc
    result <- NULL
    for(i in 2:nrow(subAssays)) {
        columnInx <- c(subAssays$Start[1]:subAssays$End[1],
                       subAssays$Start[i]:subAssays$End[i] )
        if(DEBUG==TRUE)
            cat("Creating newSheet with the following columns:", columnInx, "\n")
        newSheet <- wholeSheet[, columnInx]

        ## Create a subset of data frame subTables to match subAssays
        stRowBeg <- which(subTables$Start == subAssays$Start[i])
        stRowEnd <- which(subTables$End   == subAssays$End[i])
        stopifnot(length(stRowBeg) == 1, length(stRowEnd) == 1)
        st <- subTables[ stRowBeg:stRowEnd, ]
        ## Adjust indexes in 'st' as the subsetting adjusts the column numbers
        toPick <- (1:ncol(wholeSheet))[columnInx]
        st$newBeg <- match(st$Start, toPick)
        st$newEnd <- match(st$End, toPick)
        if(DEBUG == TRUE) {
            cat("Sub-Table subsetted:\n",
                "\ti=", i, ", Begin=", stRowBeg, ", End=", stRowEnd, "\n",
                "\tst:\n",
                sep='')
            print(st)
        }
        st$Start <- NULL
        st$End <- NULL
        colnames(st) <- c('Strain', 'Start', 'End')

        res <- parseSubSheet(sheetName, trialName, assayName, subAssayName=subAssays$ShortName[i], newSheet, st)
        result <- rbind(result, res)
    }

    ##----------------------------------------------------------------------
    ## FIX DATA (Issue 4):
    ## Sheet "QIV1-ATW HI", column E is identical to column AD; column F
    ## is identical to column AE. And the calculated columns, FoldChange
    ## and Responder, are therefore identical too.
    ##
    ## With the data extracted, we'll now cut it out (remove rows) from 'result'.
    if(sheetName == "QIV1-ATW HI") {
        badStrain <- "A/Brisbane/2/2018 (H1N1)"
        ## Index to select the Trial & Assay & Strain. Do Not Care: Subject, Day, Value.
        inxBad <- (result$Trial == 'QIV1') & (result$Assay == 'HI') & (result$Strain == badStrain)

        ## Walk the sheet to confirm the issue and locate duplicated data
        cat("\n********************\nWork on Issue #4 (Duplicated Data):\n")
        dupStrain <- NULL   # Flag; NULL means no duplicate, else strain name in 'dupStrain'
        for(strain in KnownStrains) {
            if(strain == badStrain)
                next
            cat("\tChecking strain:", strain, "\n")
            inx <-(result$Trial == 'QIV1') & (result$Assay == 'HI') & (result$Strain == strain)
            if(sum(inx) == 0) next   # Skip any strains that are not present
            stopifnot( sum(inx) == sum(inxBad) )
            if(all(myEquals(result$Value[inx], result$Value[inxBad]))) {
                cat("\t\tData matches for: strain=", strain, "\n")
                dupStrain <- c(dupStrain, strain)
            }
        }
        cat("\n\tData for strain=", badStrain, "duplicated from:", paste(dupStrain, collapse=', '), "\n")

        if( !is.null(dupStrain) ) {
            cat("\nFix Issue #4: QIV1-ATW HI duplicated data:",
                "\tDeleting data that was erroneously entered. Strain was not tested in lab.",
                sprintf("\tSheet: '%s', Strain: '%s', Subjects and Days: ALL", sheetName, badStrain),
                sprintf("\tTotal values deleted: %d", sum(inxBad)),
                paste0("\tEffected Subjects:\n",
                       wrapText(sort(unique(result$SubjectID[inxBad])), prefix='\t\t')),
                paste0("\tEffected Data 'Days':\n", wrapText(sort(unique(result$Day[inxBad])), prefix='\t\t')),
                sep='\n')
            result <- result[ !inxBad, ]
        }
    }

    return(result)
}

##' FIXME: Add documentation
parseSubSheet <- function(sheetName, trialName, assayName, subAssayName, sheet, subTables) {
    if(DEBUG == TRUE) {
        cat(sprintf('parseSubSheet(%s, %s, %s, %s, sheet=(%d x %d), subTables=(%d x %d)\n',
                    sheetName, trialName, assayName, subAssayName, nrow(sheet), ncol(sheet),
                    nrow(subTables), ncol(subTables)))
    }

    ## Different sheets have different patterns of columns - rename columns for consistency
    newColNamesV1 <- getColumnPatterns(sheet, ID=1)
    ## Find "improper", non-numeric columns and convert them to numeric. Creates some NA values.
    sheet <- fixSheetColumn(sheetName, sheet, newColNamesV1)
    ## Is this next call required?
    newColNames <- getColumnPatterns(sheet, ID=2)

    ## Build a new empty data frame for all the sub-table (i.e. Virus Strain) in LONG FORMAT.
    ## Columns are: SubjectID - Trial - Assay - SubAssay - Strain - Day (or Fraction) - Value
    ## Note: the variable "numDays" includes things other than
    ## "days". I,e,, "D00", "D28", and "D28/D00".
    N <- nrow(sheet)  ## Number of Subjects
    M <- nrow(subTables)   ## Number of Strains tested == Number of sub-tables
    numDays <- length(unique(newColNames$NewNames[!is.na(newColNames$SubSheet) & newColNames$SubSheet > 0]))
    newData <- data.frame(SubjectID=rep(sheet$SubjectID, times=M * numDays),
                          Trial=factor(rep(trialName, N * M * numDays), levels=TrialNames),
                          Assay=factor(rep(assayName, N * M * numDays), levels=AssayNames),
                          SubAssay=factor(rep(subAssayName, N * M * numDays), levels=SubAssayNames),
                          Strain=factor(rep(subTables$Strain, each=N * numDays), levels=KnownStrains),
                          Day=rep(NA_character_, N * M * numDays),
                          Value=rep(NA_real_, N * M * numDays),
                          stringsAsFactors=FALSE)

    ## Split the sheet into small sheets ('ss') based on subTables and newColNames.
    ## Then append that those sheets to the "bottom" of the one before it in 'newData'.
    for(i in 1:nrow(subTables)) {
        ind <- subTables$Start[i]:subTables$End[i]
        ind <- ind[ !is.na(newColNames$SubSheet[ind]) ]  # Clean out columns that are not useful
        ss <- as.data.frame(sheet[, ind ])
        if(DEBUG == TRUE) {
            cat('Ind=c(', ind[1], ':', ind[2], ") dim(ss)=c(", nrow(ss), " x ", ncol(ss),
                ') N=', N, ' numDays=', numDays, '\n', sep='')
        }
        stopifnot( nrow(ss) == N, ncol(ss) == numDays)

        ## Change column names
        stopifnot(is.na(ind) == FALSE)
        colnames(ss) <- newColNames$NewNames[ind]

        ## Place values into newData
        for(j in 1:ncol(ss)) {
            ## Compute indicies for placing this 'ss' correctly into 'newData[]'
            indLo <- N * numDays * (i - 1) + N * (j - 1) + 1
            indHi <- indLo + N - 1
            if(DEBUG == TRUE) {
                cat("Sheet:", sprintf('%s, %s', sheetName, colnames(ss)[j]),
                    "Into rows:", sprintf("[%d, %d]", indLo, indHi), "\n")
            }
            newData$Day[indLo:indHi] <- colnames(ss)[j]
            if(colnames(ss)[j] == 'Responder') {
                newData$Value[indLo:indHi] <- as.numeric(ifelse(ss[, j] == 'Yes', TRUE,
                                                         ifelse(ss[, j] == 'No', FALSE, NA)))
            } else if(typeof(ss[,j]) == 'character') {
                ## Something is wrong here; should see numeric values. Usually an odd entry in sheet.
                excelColInx <- (ind[1] - 1) + j
                excelColNm <- ExcelColumns[excelColInx]
                cat("*** Sheet:", sheetName, ", Column:", excelColNm,
                    ", contains non-numeric value:\n",
                    wrapText(ss[,j]), "\n")
            } else {
                newData$Value[indLo:indHi] <- as.numeric(ss[, j])
            }
        }
    }

    return(newData)
}


##----------------------------------------------------------------------
##                  FIX Sheets
## Philosophically, one should not change the data sent in by researchers.
## Instead, somehow locate the erroneous data value and change it (and
## log it!) within the code. This permits a tracking of changes, instead
## of losing track in a myriad of email, texts, and phone calls.
##
##' fix_QIV2_HI - Make the changes documented in the file, "Data-Issues_2024-08-21.txt".
##'
##' @param subTables is a data.frame defining where results for different virus strains are
##' @param wholeSheet is a tibble or data.frame containing the whole sheet of data without virus names
##' @return A modified version of "wholeSheet"
fix_QIV2_HI <- function(subTables, wholeSheet) {
    ## Tibbles do not permit easy access to individual cells. Make it a data.frame()
    if(is_tibble(wholeSheet)) {
        wholeSheet <- as.data.frame(wholeSheet)
    }

    ## Issue #1: AR-18 is 'ok'; should be EMPTY
    colNum <- which(ExcelColumns == 'AR')
    rowNum <- 18 - 3
    if(is.na(wholeSheet[rowNum, colNum]) == FALSE & wholeSheet[rowNum, colNum] == 'ok') {
        cat('Fix Issue #1: QIV2UIB HI, AR-18: convert "ok" to NA.\n')
        wholeSheet[rowNum, colNum] <- NA
        wholeSheet[, colNum] <- as.numeric(wholeSheet[, colNum])
    }

    ## Issue #2a: AC-43 is '5' and should be NA
    colNum <- which(ExcelColumns == 'AC')
    rowNum <- 43 - 3
    if(is.na(wholeSheet[rowNum, colNum]) == FALSE & wholeSheet[rowNum, colNum] == 5) {
        cat('Fix Issue #2a: QIV2UIB HI, AC-43: convert "5" to NA.\n')
        wholeSheet[rowNum, colNum] <- NA
    }

    return(wholeSheet)
}

##----------------------------------------------------------------------
#' getColumnPatterns - confirm that all columns are correctly named and consistent
#'
#' There are lots of columns in this sheet with many repeated values
#' as multiple virus strains are tested. As Excel (and R) don't like
#' to have non-unique column names, the 'tibble' reading code has added
#' a "...N", where 'N' is a number of the column, to differentiate the
#' column names. For example, day-0, named 'D0' in several columns becomes
#' 'D0...5', 'D0...10', 'D0...15', etc.
#'
#' @param sheet A data.frame (or tibble) containing the whole worksheet from row 2 down.
#' @param ID is added for debugging - it permits know which time this function is called
#' @return A data.frame of:
#'     ColNames = original column names of sheet
#'     ColType = Uses 'typeof()' to determine column type. Used to locate non-numeric data columns.
#'     SubSheet = integer 'n' from above. Which sub-experiment in sheet
#'     DayNumber = Which 'day' is this column? 0, 30, 58, etc. May be NA.
#'     Fraction = Which fraction is this column? D58/D00 or D30/D00, etc. May be NA.
#'     NewNames = New column names to replace 'ColNames' above
getColumnPatterns <- function(sheet, ID) {
    stopifnot(is.data.frame(sheet), is.null(colnames(sheet)) == FALSE,
              is.numeric(ID), length(ID) == 1)
    ## Expected columns include "SubjectID", "Age (years)", "Gender",
    ## "QIV doses", "D0", "D28", "Fold-increase", "Responder", "".
    ## Columns that are repeated get the "...N" treatment, even the ""
    ## column which becomes "...9", "...14", etc. See Global Variable
    ## "KnownColumnNames" for valid names.

    ## Work on the '...N' first. Strip this value.
    ## Variables: cn=column names
    cn <- gsub('^(.*)\\.\\.\\.[0-9]+$', '\\1', colnames(sheet) )

    ## Figure out the repeating groups
    tb <- table(cn)
    tb <- tb[ names(tb) != "" ]    # Remove the EMPTY columns (un-named columns used to space things)
    nonRepeat <- names(tb)[tb == 1]
    numRepeats <- tb[tb > 1]

    ## Check all column names have same counts
    if( any(numRepeats[1] != numRepeats) ) {
        cat("Column names do not seem to match in count:\n")
        print(numRepeats)
        if(DEBUG == FALSE) stop("Can not proceed.")
    }

    ## Collect the names used for the repeating data (i.e. Same name but different virus)
    sn <- names(numRepeats)
    stopifnot(sn %in% KnownColumnNames)

    if(DEBUG == TRUE) {
        cat("\ngetColumnPatterns(ID=", ID, ")\n",
            "colnames:\n", wrapText(colnames(sheet)), "\n\n",
            "cn:\n", wrapText(cn), "\n\n",
            "sn:\n", wrapText(sn), "\n\n",
            "Empty columns dropped = ", sum(cn == ""), "\n",  wrapText(colnames(sheet)[cn == '']), "\n\n",
            sep='')
        cat('Non-repeated columns:\n', wrapText(nonRepeat), "\n\n", sep='')
        cat('Repeated columns and counts:\n')
        print(numRepeats)
    }

    ## Compute the subsheet region, e.g. region for a single virus strain
    subsheet <- rep(NA, length(cn))
    for(nm in names(numRepeats)) {
        inx <- cn == nm
        subsheet[inx] <- 1:numRepeats[1]
    }
    ## Add a ZERO for the non-repeated fields
    subsheet[ match(nonRepeat, cn) ] <- 0

    ## Change 'cn' to contain the new names; translation of names
    newNames <- cn
    ## Work on pattern for simple Day-of-Visit, "^D[0-9]+$"
    inx <- grepl('^D[0-9]+$', cn)
    val <- as.numeric(gsub('^D', '', cn[inx]))
    newNames[inx] <- sprintf('D%03d', val)

    ## Work on pattern for range for Day-Of-Visit "^D[0-9]+-[0-9]+$", normally, "D3-8"
    inx <- grepl('^D[0-9]+-[0-9]+$', cn)
    val1 <- as.numeric(gsub('^D([0-9]+)-[0-9]+$', '\\1', cn[inx]))
    val2 <- as.numeric(gsub('^D[0-9]+-([0-9]+)$', '\\1', cn[inx]))
    newNames[inx] <- sprintf('D%03d-%d', val1, val2)

    ## Change "Fold-increase" to "FoldChange"; other names too.
    newNames <- gsub('Fold-increase', 'FoldChange', newNames)
    newNames <- gsub("Age \\(years\\)", "Age-years", newNames)
    newNames <- gsub("Pre", "PreVac", newNames)
    newNames <- gsub("Post", "PostVaxMax", newNames)
    newNames <- gsub("QIV doses", "QIV-doses", newNames)

    ## Compute the "Day Number" - the day of the visit. Not used in later code, IIRC.
    dayNumber <- rep(NA_integer_, length(newNames))
    inx <- grepl('^D[0-9]+', newNames)
    dayNumber[inx] <- as.integer(gsub('^D([0-9]+).*$', '\\1', newNames[inx]))

    ## Build data structure (data.frame) to return.
    ## Shows: Old column names, where virus sub-sets are, which "day", and new names
    dat <- data.frame(ColNames=colnames(sheet),    # Original column names
                      ColType=unname(sapply(sheet, function(x) typeof(x))),
                      SubSheet=subsheet,           # Which data group (virus) for these columns
                      DayNumber=dayNumber,         # If a "Day", which Day is it? 0, 28, etc
                      NewNames=newNames,           # What shall we call these new columns?
                      stringsAsFactors=FALSE)
    return(dat)
}

#' Parse the first row of worksheet to get a description of the assay.
#'
#' The first row of the Excel sheet is used to define the assay being reported on
#' in human-readable format. That is, the assay description is somewhat long-winded
#' and easily understood. A lookup table in the GLOBALs are, above, is used to
#' translate these long, descriptive names into a shorter name for writing to the
#' LONG format file. In some cases, e.g., the ELISA data, there is more than one
#' assay per sheet, where those assay could be characterized as "sub-assays". That
#' is what we'll call the new column in the LONG-format file.
#' @param excelFile Filename of the Excel file that we're parsing
#' @param sheetName Name of the worksheet within the Excel file.
#' @return data.frame containing:
#'    Start = column number in which this sub-assay starts (number from 1)
#'    End = column number in which this sub-assay ends
#'    SubAssay = Name that is parsed out from row 1
#'    ShortName = Name looked up from the table
#' @note For consistancy, the first few columns will be listed and have a SubAssay name of "".
parseAssayRow <- function(excelFile, sheetName) {
    ## Parameters are already checked. No additional checking here.

    ## Here, I would like to read one line or just a header row (colnames() ), however,
    ## if I do that, read_xlsx() deletes the leading blank columns, moving my initial entry
    ## from column 5 (for "QIV1-ATW HI") to column 1, defeating the whole purpose of this
    ## subroutine. I do believe this is a bug in read_xlsx() but haven't time to do anything
    ## about it. Parameters removed: "n_max=1, skip=0, .name_repair='unique_quiet'".
    s <- read_xlsx(path=excelFile, sheet=sheetName, col_names=FALSE, trim_ws=TRUE)
    cn <- as.character(s[1,])
    if(DEBUG == TRUE) {
        cat("\nparseAssayRow(): Found columns named:\n\t",
            paste(paste(ExcelColumns[1:length(cn)], cn, sep=': '), collapse="\n\t"),
            "\n\n", sep='')
    }
    startAssay <- which( !is.na(cn) )
    stopifnot(startAssay[1] > 1, length(cn) > startAssay[length(startAssay)])
    ## This lookup might need changing if it neeeds to be Trial and Assay specific.
    shortNameInx <- match(cn[!is.na(cn)], SubAssays$FullName)

    subAssay <- data.frame(Start=c(1, startAssay),
                           End=c(startAssay-1, length(cn)),
                           StartXLS=ExcelColumns[c(1, startAssay)],
                           EndXLS=ExcelColumns[c(startAssay-1, length(cn))],
                           FullName=c("NOASSAY", cn[!is.na(cn)]),
                           ShortName=c("", SubAssays$ShortName[shortNameInx] )
                           )
    return(subAssay)
}

#' Parse row of worksheet for virus strain, returning sub-table data.frame giving columns and strain.
#'
#' The second row of these spreadsheets contains the strains that were tested.
#' Each strain is in the first sub-table column that the data corresponds to.
#' Unlabled columns are data associated with that sub-table.
#' @param excelFile Filename of Excel file that we're parsing
#' @param sheetName Name of the worksheet within the Excel file that we're parsing
#' @return data.frame containing:
#'     Strain = a canonical strain name from KnownStrains. If findable, then NA
#'     Start = integer column number where 'Strain' experiment starts
#'     End = integer column number where 'Strain' experiment ends
parseVirusRow <- function(excelFile, sheetName) {
    ## No parameter checking as the calling function has done that.
    ## Read in each sheet and find the names of the Virus Strains
    ## Note: Un-named columns, i.e. empty cells in row 1, are labeled "...[0-9]+".
    ## Ignore those empty cells and pick other named cells for the Virus strains.
    s <- read_xlsx(path=excelFile, sheet=sheetName, skip=1,
                   n_max=1, trim_ws=TRUE, .name_repair='unique_quiet')
    cn <- colnames(s)[2:ncol(s)]              ## Find column names excluding column 1 (=SubjectID)
    inx <- grepl('^[[:blank:]]*\\.\\.\\.[0-9]+$', cn)   ## Index to "empty" cells; ignore them
    ## Pull out the non-empty cells as "strains".
    strains <- cn[ !inx ]
    strains <- gsub('\\.\\.\\.[0-9]+$', '', gsub('[[:blank:]]+', ' ',  strains))
    if(DEBUG == TRUE)
        cat("parseVirusRow: Strains:\n", wrapText(strains), "\n", sep='')
    startCol <- which( !inx ) + 1           ## Add +1 due to 'cn' excluding column 1
    stopifnot(length(strains) == length(startCol))

    endCol <- startCol - 1
    endCol <- c(endCol[2:length(endCol)], ncol(s))

    ## Clean up the strains - who knew there could be so many spellings
    if(any( (strains %in% KnownStrains) == FALSE)) {
        ## Not Known; Try to find the name in the 'AliasStrains' table and translate
        inx <- match(strains, AliasStrains$Alias)
        if(any( !is.na(inx) )) {
            cat("\nWarning: Substituting strain(s):\n\t",
                paste(paste0(strains[ !is.na(inx) ], ' --> ',
                             AliasStrains$Canonical[ inx[!is.na(inx)] ]),
                      collapse='\n\t'),
                "\n\n", sep='')
            strains[ !is.na(inx) ] <- AliasStrains$Canonical[ inx[!is.na(inx)] ]
        }

        inx <- (strains %in% KnownStrains)
        if(any(inx == FALSE)) {
            cat("\n*** WARNING: Unknown Strain(s) in Data\n",
                "\nKnown Strains:\n\t",
                paste(KnownStrains, collapse='\n\t'),
                "\nRecognized:\n\t",
                paste(strains[inx], collapse='\n\t'),
                "\nNot-Recognized:\n\t",
                paste(strains[!inx], collapse='\n\t'),
                "\n\n", sep='')
            strains[inx == FALSE] <- NA
        }
    }

    ## Build a table to return these values
    subTable <- data.frame(Strain=factor(strains, levels=KnownStrains),
                           Start=startCol,
                           End=endCol,
                           stringsAsFactors=FALSE)
    return(subTable)
}

#' Parse the values from the worksheet including header names. Start at Row 2.
#'
#' @param excelFile Filename from which to parse the sheet
#' @param sheetName Worksheet name from which to parse the values
#' @return data.frame containing the cleaned up values
readDataSheet <- function(excelFile, sheetName) {
    ## Accept function parameters as they're checked in the calling function
    ## NOTE: the option .name_repair is using an undocumented attribute, 'unique_quiet',
    ##       which is described here:
    ## https://github.com/tidyverse/readxl/issues/580
    s <- read_xlsx(path=excelFile, sheet=sheetName, skip=2,
                   trim_ws=TRUE, .name_repair='unique_quiet')

    return(s)
}

#' fixSheetColumn - Convert a sheet's column from 'character' to 'numeric'
#'
#' @param sheetName is the name of the sheet; used to document any conversions.
#' @param sheet is a tibble returned by 'readDataSheet()'
#' @param colPattern is a data.frame returned by 'getColumnPatterns()'
#' @return updated sheet with 'character' column set to 'double'
fixSheetColumn <- function(sheetName, sheet, colPattern) {
    ## Fix: Columns of 'Day-NN' data should be numeric. Find and change non-numeric data.
    inxDayCol <- grepl('^D[0-9]+', colPattern$NewNames)
    inxNonDouble <-  inxDayCol & colPattern$ColType != 'double'
    if(any(inxNonDouble == TRUE)) {
        for(i in which(inxNonDouble)) {
            inxNonNumb <- (!is.na(sheet[, i, drop=TRUE])) & (grepl('^[0-9]+$', sheet[, i, drop=TRUE]) == FALSE)
            cat("*** Sheet:", sheetName, "column: ", i, "(", ExcelColumns[i], ") is non-numeric.\n",
                "\tData error in row(s):", paste(which(inxNonNumb), collapse=', '), "\n\tChanging to 'NA'.\n")
            sheet[inxNonNumb, i] <- NA   # Fix the non-numeric value
            sheet[, i] <- as.numeric(sheet[, i, drop=TRUE])
        }
    }
    return(sheet)
}

##********************************************************************************
##                                    MAIN
##********************************************************************************
## Create a dividing line for a display divider
dhLine <- paste0(rep("=", 70), collapse='')

## Dsiplay Known Strains to ensure we have the dictionary correct
cat("\nKnown Strains:\n\t", paste(KnownStrains, collapse='\n\t'), "\n", sep='')

cat("\nUsing these Strain Alias Names:\n")
print(AliasStrains)

## Figure out which sheets are present
sheetNames <- excel_sheets(inFile)

## Drop out the Demographics and "Sort By Age"  sheets
inx <- grepl('demographics|sort by', sheetNames)
if(sum(inx) > 0) {
    cat("\n*** Drop sheet(s):\n\t'", paste(sheetNames[inx], collapse="'\n\t'"), "'\n", sep='')
}
sheetNames <- sheetNames[ inx == FALSE ]

## Convert "sheetNames" into "controlled-vocabulary" via some RegEx
sheets <- parseSheetNames(sheetNames)
cat("\nProcessing sheets:\n")
print(sheets)
cat("\n",dhLine, "\n", sep='')

## Loop over the sheets in the order:
##   Assay {HI, MN, ELLA, ELISA} then Trial {QIV1, QIV2, QIV3}
cat("\n",dhLine, "\n", sep='')
cat("Processing all sheets, organized by Assay and Trial:\n\n")

## "dat" is the final data frame to jam all the data into via rbind()
dat <- NULL
for(assay in AssayNames) {
    ##if(assay != 'ELISA') next
    for(trial in TrialNames) {
        ind <- which((sheets$Assay == assay) & (sheets$Trial == trial))
        for(i in seq_along(ind)) {
            cat(dhLine,
                sprintf("Processing sheet %d: '%s'", ind[i], sheets$SheetName[ ind[i] ]),
                sprintf("\tTrial=%s, Assay=%s", trial, assay),
                " ",
                sep='\n')
            x <- parseSheet(inFile, sheets$SheetName[ ind[i] ],
                            sheets$Trial[ ind[i] ], sheets$Assay[ ind[i] ])
            dat <- rbind(dat, x)
        }
    }
}

##********************************************************************************
## Compute the Responder/Non-Responder status for the HI assay
## This is slightly messy because:
##    QIV1 has D000 & D028
##    QIV2 has D000, D003-8, D028 & D058 with a complex rule for max post-vaccine
##    QIV3 has D000, & D058
##
## <pre-vaccine> := titer at D000
## <max post-vaccine> := QIV1=D028, QIV3=D058, QIV2=max(D030, D058) unless NA, then D003-8.
## FoldChange := <max post-vaccine> / <pre-vaccine>
## Responder := ( <max post-vaccine> >= 40 ) & ( FoldChange >= <cut off> )
##    <cut off> := Threshold of 2.5 or 4.0.
##
## The sheet distributed by Cox, et al. used 2.5.
stop("here for now")
assay <- 'HI'
resp <- list()  # One data frame per trial
for(trial in TrialNames) {
    if(trial == 'None') next
    resp[[trial]] <- data.frame(SubjectID=unique(dat$SubjectID[dat$Trial == trial]))
    for(i in 1:nrow(VaxStrains) ) {
        strain <- VaxStrains$Strain[i]
        inx <- (dat$Trial == trial) & (dat$Assay == assay) & (dat$Strain == strain)
        days <- sort(unique(dat$Day[inx]))
        subjects <- unique(dat$Subject[inx])
        ## Different days for different trials; different rules as well.
        if(trial == 'QIV1') {
            stopifnot(c('D000', 'D028') %in% days)
            ## Collect the Baseline (Pre-Vacination) value
            inxBL <- inx & (dat$Day == 'D000')
            stopifnot(dat$SubjectID[inxBL] == resp[[trial]]$SubjectID)
            preVac <- dat$Value[inxBL]
            ## Collect the Post-Vaccination value
            inxPV <- inx & (dat$Day == 'D028')
            stopifnot(dat$SubjectID[inxPV] == resp[[trial]]$SubjectID)
            postVac <- dat$Value[inxPV]

        } else if(trial == 'QIV2') {
            stopifnot(c('D000', 'D003-8', 'D030', 'D058') %in% days)
            ## Collect the Baseline (Pre-Vacination) value
            inxBL <- inx & (dat$Day == 'D000')
            stopifnot(dat$SubjectID[inxBL] == resp[[trial]]$SubjectID)
            preVac <- dat$Value[inxBL]
            ## Collect the Post-Vaccination value
            inxPV0 <- inx & (dat$Day == 'D003-8')  # Use only if needed
            inxPV1 <- inx & (dat$Day == 'D030')
            inxPV2 <- inx & (dat$Day == 'D058')
            stopifnot(dat$SubjectID[inxPV0] == resp[[trial]]$SubjectID,
                      dat$SubjectID[inxPV1] == resp[[trial]]$SubjectID,
                      dat$SubjectID[inxPV2] == resp[[trial]]$SubjectID)
            postVac <- myPMax(dat$Value[inxPV1], dat$Value[inxPV1])
            inxNA <- is.na(postVac)
            postVac[inxNA] <- dat$Value[inxPV0][inxNA]

        } else if(trial == 'QIV3') {
            stopifnot(c('D000', 'D058') %in% days)
            ## Collect the Baseline (Pre-Vacination) value
            inxBL <- inx & (dat$Day == 'D000')
            stopifnot(dat$SubjectID[inxBL] == resp[[trial]]$SubjectID)
            preVac <- dat$Value[inxBL]
            ## Collect the Post-Vaccination value
            inxPV <- inx & (dat$Day == 'D058')
            stopifnot(dat$SubjectID[inxPV] == resp[[trial]]$SubjectID)
            postVac <- dat$Value[inxPV]
        } else {
            stop('Should never have a trial named:', trial)
        }

        ## Compute Fold Change and Responder Status
        foldChange <- postVac / preVac
        responder <- (postVac >= 40) & (foldChange >= 2.5)

        ## Build data frame to add (via rbind) to 'dat', long-format
        N <- length(subjects)
        tmpDB <- data.frame(SubjectID=subjects,
                            Trial=rep(trial, N),
                            Assay=rep(assay, N),
                            SubAssay=rep('HI-Responder', N),
                            Strain=rep(strain, N),
                            Day='

        ## Build data frame to rbind to resp[[trial]]
        tmpDF <- data.frame(PreVac=preVac, PostVac=postVac, FC=foldChange, Resp=responder)
        colnames(tmpDF) <- paste0(colnames(tmpDF), '-', VaxStrains$ShortName[i])

        resp[[trial]] <- cbind(resp[[trial]], tmpDF)
    }
}

##********************************************************************************
## Output the data in a long-format CSV file
cat(dhLine, '\nWriting output file: "', outName, '", ',
    nrow(dat), " rows x ", ncol(dat), " columns.\n", sep='')
write.csv(dat, file=outName, row.names=FALSE)

## Completed.
runTime <- difftime(Sys.time(), today, units='secs')
cat(dhLine, "\nCompleted. Run-time:", runTime, "secs.\n")

if( !interactive() ) {
    sink(type='message')
    sink()
}

cat("Completed.\n")
