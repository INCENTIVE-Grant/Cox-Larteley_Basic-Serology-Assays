# Hemagglutination Inhibition Assay (HI) CSV File

The CSV file,
`Cox-Lab-Serology_QIV-1-2-3_Updated_2025-03-31_20260128.csv`,
contains the same data as the Excel file,
`Cox-Lab-Serology_QIV-1-2-3_Updated_2025-03-31.xlsx`.
The difference is the format. The Excel file is in *wide-format* while
the CSV file is in *long-format*. For a comparison of the two formats,
see: [Long vs. Wide Data: What’s the
Difference?](https://www.statology.org/long-vs-wide-data/).

The CSV file is derived programatically from the Excel file via the
R-program, `parse-Cox-Serology-Data.R`, version 2.0.

## Column definitions of the CSV file

The columns of the CSV file are:

SubjectID
: The ID used for this subject in the trial

Trial
: This data point is from which clinical trial: *QIV1*,
  *QIV2*, or *QIV3*

Assay
: Which assay. All of these data are the Hemagglutination Inhibition
  Assay, *HI*.

SubAssay
: Some Assays have different versions. For example, the HI Assay has
  both tests against the viral strains used in the vaccine as well as
  tests against additional strains.

Strain
: Which influenza virus strain was tested in the HI assay. A full list
  in WHO standard format is shown below.
  
Day
: A slight misnomer as it is not only *Days*. This value defines the
  type of *value* measured. It could be the value at Day 0 (*D000*),
  Day 3 to 8 (*D003-8*, Day 28 (*D028*), Day 30 (*D030*), Day 58
  (*D058*), Day 180 (*D180*), Day 360 (*D360*). In addition to *Days*,
  other values are: Fold Change (*FoldChange*), Post vaccination
  maximum value (*PostVax*), Pre-vaccination value (*PreVac*), or
  if the subject responded to the vaccination (*Responder*).

Value
: The numerical value the assay for the different Days; the
  fold-change of: (Post-vacination HI assay / Pre-vaccination HI
  assay); or for *Responder*, a value of 1 if the subject responded to
  the vaccine and 0 if they did not respond.

Note that *Responder* is defined as:

1. A post-vacination titre of $\geq$ 40
and
2. A fold-change of $\geq$ 2.5.

## Valid Virus strains

The WHO has defined a standard for naming influenza strains. The
following list follows that standard. The standard includes
specifications for the punctuation and the meaning of each field in
the delimited name. See: [Naming influenza
viruses](https://www.cdc.gov/flu/about/viruses-types.html#cdc_generic_section_4-naming-influenza-viruses)

- A/Brisbane/2/2018 (H1N1)
- A/Brisbane/57/2007 (H1N1)
- A/California/7/2019 (H1N1)
- A/Darwin/9/2021 (H3N2)
- A/Hong Kong/4801/2014 (H3N2)
- A/Panama/2007/1999 (H3N2)
- A/Singapore/INFIMH-16-0019/2016 (H3N2)
- A/Switzerland/9715293/2013 (H3N2)
- A/Tasmania/503/2020 (H3N2)
- A/Victoria/2570/2019 (H1N1)
- A/Wisconsin/588/2019 (H1N1)
- B/Austria/1359417/2021
- B/Phuket/3073/2013
- B/Washington/2/2019

One assay uses a mixture of strains; those mixtures are listed here.

- A/Equine/Prague/1/1956 (H7N7) + A/California/7/2019 (H1N1)
- A/Turkey/Massachusetts/3740/1965 (H6N2) + A/Texas/50/2012 (H2N2)
- A/Turkey/Massachusetts/3740/1965 (H6N2) + B/Yamagata/16/1988 (NB)

## Accessing the CSV data

Basic code to read and view the CSV data is shown below in
the R programming language.

### Code for R program

```r
#!/usr/bin/env Rscript
##
## Basic R code to read the CSV file and show some
## simple counts of the data values.
##
## VERSION HISTORY
## [2024-10-13 MeD] Initial version
## [2025-10-17 MeD] Updated for the new data upload
##
##**********************************************************************
library(AnalysisHeader)
source('Controlled-Vocab.R')

## Which file are we reading?
inFile <- 'Cox-Lab-Serology_QIV-1-2-3_Updated_2025-03-31_20260128.csv'

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

```

### Results of running the R program

```
-----------------------------------------------------------------------------------
Program: basic-reader.R
Version: 1.1, Git Tag: v2.0
Run Date: 2026-01-28 21:15:13 EST
User: hvp
Hostname: xena
Working Dir: /home/hvp/Documents/Projects/2025-10-13_Cox_Zenodo-Upload
Arguments: 
-----------------------------------------------------------------------------------
R version 4.5.0 (2025-04-11)
Platform: x86_64-pc-linux-gnu
Running under: Ubuntu 24.04.3 LTS

Matrix products: default
BLAS:   /usr/lib/x86_64-linux-gnu/blas/libblas.so.3.12.0 
LAPACK: /usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.12.0  LAPACK version 3.12.0

locale:
 [1] LC_CTYPE=en_US.UTF-8       LC_NUMERIC=C               LC_TIME=en_US.UTF-8       
 [4] LC_COLLATE=en_US.UTF-8     LC_MONETARY=en_US.UTF-8    LC_MESSAGES=en_US.UTF-8   
 [7] LC_PAPER=en_US.UTF-8       LC_NAME=C                  LC_ADDRESS=C              
[10] LC_TELEPHONE=C             LC_MEASUREMENT=en_US.UTF-8 LC_IDENTIFICATION=C       

time zone: America/New_York
tzcode source: system (glibc)

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

other attached packages:
[1] AnalysisHeader_1.6

loaded via a namespace (and not attached):
[1] compiler_4.5.0
----------------------------------------------------------------------------------- 
Vocabulary Version: v1.1 
Input file: Cox-Lab-Serology_QIV-1-2-3_Updated_2025-03-31_20260128.csv 

Reading input file: Cox-Lab-Serology_QIV-1-2-3_Updated_2025-03-31_20260128.csv 

How big is the dataset?
	Size in memory is 652288 bytes.
 	as 11422 rows x 7 columns.

An excerpt of the data looks like:
   SubjectID Trial Assay                 SubAssay                      Strain  Day
1 QIV1ATW003  QIV1    HI HI titre, vaccine strain A/Victoria/2570/2019 (H1N1) D000
2 QIV1ATW005  QIV1    HI HI titre, vaccine strain A/Victoria/2570/2019 (H1N1) D000
3 QIV1ATW010  QIV1    HI HI titre, vaccine strain A/Victoria/2570/2019 (H1N1) D000
4 QIV1ATW011  QIV1    HI HI titre, vaccine strain A/Victoria/2570/2019 (H1N1) D000
5 QIV1ATW012  QIV1    HI HI titre, vaccine strain A/Victoria/2570/2019 (H1N1) D000
6 QIV1ATW013  QIV1    HI HI titre, vaccine strain A/Victoria/2570/2019 (H1N1) D000
  Value
1    20
2    20
3     5
4     5
5    20
6    10

How many values for each trial?

QIV1 QIV2 QIV3 
3800 6532 1090 

How many different assays?
                              Assay
SubAssay                       ELISA ELLA   HI   MN
  HA IgG endpoint titre         2040    0    0    0
  HI titre, non-vaccine strain     0    0 1804    0
  HI titre, vaccine strain         0    0 1704    0
  HI-Responder                     0    0 1936    0
  IgG endpoint titre             400    0    0    0
  NA IgG endpoint titre          576    0    0    0
  NA Inhibiting Ab titre           0 1266    0    0
  Neutralizing Ab titre            0    0    0 1696

How many values use each strain in each trial?
                                                                   
                                                                    QIV1 QIV2 QIV3
  A/Brisbane/2/2018 (H1N1)                                           100    0    0
  A/Brisbane/57/2007 (H1N1)                                          100    0    0
  A/California/7/2019 (H1N1)                                         300  276    0
  A/Darwin/9/2021 (H3N2)                                             100  276    0
  A/Equine/Prague/1/1956 (H7N7) + A/California/7/2019 (H1N1)           0  276    0
  A/H6N2                                                             100    0   46
  A/H7N1                                                             100    0   46
  A/Hong Kong/4801/2014 (H3N2)                                       100    0    0
  A/Panama/2007/1999 (H3N2)                                          100    0    0
  A/Singapore/INFIMH-16-0019/2016 (H3N2)                             200    0    0
  A/Switzerland/9715293/2013 (H3N2)                                  100  276    0
  A/Tasmania/503/2020 (H3N2)                                         500 1012  238
  A/Turkey/Massachusetts/3740/1965 (H6N2) + A/Texas/50/2012 (H2N2)     0  276    0
  A/Turkey/Massachusetts/3740/1965 (H6N2) + B/Yamagata/16/1988 (NB)    0  276    0
  A/Victoria/2570/2019 (H1N1)                                        500 1012  238
  A/Wisconsin/588/2019 (H1N1)                                        100  276    0
  B/Austria/1359417/2021                                             100  276    0
  B/H6NB                                                             100    0   46
  B/Phuket/3073/2013                                                 600 1150  238
  B/Washington/2/2019                                                600 1150  238

How many values use each 'Day' in each trial?
            
             QIV1 QIV2 QIV3
  D000       1500 1012  345
  D003-8        0  920    0
  D028       1500    0    0
  D030          0 1012    0
  D058          0 1012  345
  D180          0  920    0
  D360          0  920    0
  FoldChange  200  184  100
  PostVax     200  184  100
  PreVac      200  184  100
  Respponder  200  184  100

Completed.

```
