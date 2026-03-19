# Basic Serology Assays: Excel data parser

The Cox lab at the University of Bergen (UiB), Norway, performed the
basic serology assays on the EU samples from the INCENTIVE
Consortium's clinical trial of approximately 50 elderly (QIV-1), 46
children (QIV-2) and 25 infants (QIV-3). These assays include the
Hemagglutination Inhibition Assay (HAI or HI), microneutralization
(MN), ELISA, and Enzyme-Linked Lectin Assay (ELLA).

## Files present here

The files here are R-scripts for parsing the summarized data,
comparing the parsed results with previously parsed datasets, and some
very basic example code for using the data. In addition, the log files
created when the data were parsed by this code is also present as an
aid to others attempting to get this code to run.

### The Excel data file parser

The primary file here is the `parse-Cox-Serology-Data.R` which
converts the multi-sheet Excel data file into a single, long-format
CSV file. The log file of the data uploaded to Zenodo is here:
`parse-Cox-Serology-Data_20260317.log`.

### A Comparison with the previous version

The time between versions of the Excel data file was quite long so I
wrote a quick-n-dirty R-program to compare the previous CSV file with
the newly generated one. The program is `compareWithPrevious.R` and
its logs are in the two files, `compareWithPrevious_20260317.log` and
`compareWithPrevious_20260317.pdf` The first reports differences
between the two datasets (early version vs current version) in text
and the second shows any changes graphically. The 'rugs' in red and
blue show where a value is NA in one dataset but non-NA in the other.

The results in these two logs show some small changes.  In QIV2, there
are some changes to values, where values shift columns, indicating
that they were entered in under the wrong Day.  In QIV3, there were
deletions of subjects where there were no measured values to work
with, i.e. there were only missing values present.

An additional quick program, `compareResponder.R`, was prepared and
run to compare the values of the Responder/Non-Responder spreadsheet,
which was circulated within INCENTIVE in June 2024, with values
computed with the current dataset. In this case, there were no changes
detected in QIV1 and QIV2. In QIV3, there was a single change in which
subject CHU017 went from being a "non-responder" to an "unknown"
(missing value). These results can be viewed in the log file,
`compareResponder_20260317.log`.

### A couple of simple programs to work with the CSV

I have included a couple of simple programs to show how one might
start to look at or work with the data. Any data scientist will find
these trivial, but someone just starting analysis might find it
helpful to have a working example.

The program, `basic-reader.R`, reads the CSV data into R and then
tabulates various values from the data set and prints them on STDOUT.
The program, `simplePlot.R`, plots a few aspects of the data using the
library, `lattice`, which is quite good for initial data analysis.
