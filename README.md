# Basic Serology Assays Excel data parser

The Cox lab at the University of Bergen (UiB), Norway, performed the
basic serology assays on the samples from the INCENTIVE Consortium's
clinical trial of approximately 50 elderly (QIV-1), 50 children
(QIV-2) and 50 infants (QIV-3). These assays include the
Hemagglutination Inhibition Assay (HAI or HI), microneutralization,
ELISA, and Enzyme-Linked Lectin Assay (ELLA).

## Files present here

The files here are R-scripts for parsing the summarized data,
comparing the parsed results with previously parsed datasets, and some
very basic example code for using the data. In addition, the log files
created when the data were parsed by this code is also present as an
aid to others attempting to get this code to run.

### The Excel file parser

The primary file here is the `parse-Cox-Serology-Data.R` which
converts the multi-sheet Excel data file into a single, long-format
CSV file. The log file of the data uploaded to Zenodo is here:
`parse-Cox-Serology-Data_20260209.log`.

### A Comparison with the previous version

The time between versions of the Excel file was quite long so I wrote
a quick-n-dirty R-program to compare the previous CSV file with the
newly generated one. This code is not really meant for re-use; it
isn't well commented and is in fact out-of-date with the current
format of the CSV file becuase the latest version of the CSV file
alters the names of the subjects to be consistent with how other labs
named the subjects (i.e. "QIV1ATW003" --> "ATW003").  This simple
change means that all comparisons of subject IDs will fail without
recoding the program.

The program is `compareWithPrevious.R` and its logs are across two
files, `compareWithPrevious_20260204.log` and `compareWithPrevious_20260204.pdf`
which graphically compares the stored values for identity.

Though I have this program here, I do not expect it to be run again. I
have used it to compare the previous data release with this current
release and found no differences. This is important to the INCENTIVE
Consortium as the early release of the data was circulated as a
Responder/Non-Responder spreadsheet for analysts to work with. This
confirmation of no change between versions is critical for their work.

### A couple of simple programs to work with the CSV

I have inclueded a couple of simple programs to show how
one might start to look at or work with the data. Any
data scientist will find these trivial, but someone just
starting analysis might find it helpful to have a working
example.

The program, `basic-reader.R`, reads the CSV data into R and then
tabulates various values from the data set and prints them on STDOUT.
The program, `simplePlot.R`, plots a few aspects of the data using the
library, `lattice`, which is quite good for initial data analysis.
