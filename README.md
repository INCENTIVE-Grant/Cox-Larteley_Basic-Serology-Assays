# Cox Lab Serology Assays Results Dataset

**Written by:** Rebecca Cox, Sarah L.

**Last Update:** 2026-01-28

## INCENTIVE Project

The [INCENTIVE Grant](https://cordis.europa.eu/project/id/874866) is
an EU Horizon H2020 (grant no. 874866) and the Dept. of Biotechnology,
Govt.  of India (project no. BT/IN/EU-INF/16/AP/19-20/11746). It is a
5-year grant for studying the response to influenza vaccination in
India and Europe in at risk populations (infants, children and
elderly). The aim is to study the immunological response to licensed
quadrivalent, inactivated, influenza vaccine and to identify
biomarkers that predict vaccine response. Blood samples were collected
from the trial subjects, both before and after vaccination.

## This Dataset in Context

Serology measures are a series of classic techniques for measuring the
immune response in blood samples. A common techniques for measuring
influenza virus is the [Hemagglutination
Assay](https://en.wikipedia.org/wiki/Hemagglutination_assay) which
relies on the influenza virus haemagglutinins ability to agglutinate
red blood cells. An extension of this assay relies on the ability of
serum antibodies to prevent agglutination and this gives an indirect
measure of the subject's antibodies against the virus. It is called
the Hemagglutination Inhibition Assay (HI).

In the case of the INCENTIVE Grant, the HI assay will form the
cornerstone for determining which subjects responded to the influenza
vaccine. Other studies will rely, at least initially, on the
responder/non-responder status for the detection of biomarkers that
might predict responder status prior to vaccination.

Additional serological assay results include those from the
_microneutralization_ (MN), ELISA, and Enzyme-Linked Lectin Assay
(ELLA. McCoy et al, 1983 Anal. Bioc. 130(2):437-444).

### Details of Haemagglutination Inhibition (HI) assay

To ensure standardized results we used the FLUCOP consortium consensus
protocol (Waldock, et al, Haemagglutination inhibition and virus
microneutralisation serology assays: use of harmonised protocols and
biological standards in seasonal influenza serology testing and their
impact on inter-laboratory variation and assay correlation: A FLUCOP
collaborative study. Frontiers in immunology, 14: 1155552. DOI:
10.3389/fimmu.2023.1155552).

One volume of serum was incubated with four volumes of
receptor-destroying enzyme (RDE) (Seiken, Japan) at 37°C overnight and
subsequently heat-inactivated at 56°C for 30 minutes. All RDE-treated
sera were pretreated with turkey red blood cells at 4°C for 1 hour, to
remove nonspecific binding. Duplicate serial double dilutions of the
treated sera were prepared from 1/5. Each dilution was mixed with 4
hemagglutinating units of influenza virus from the National Institute
for Biological Standards and Control, UK and 0.7% turkey red blood
cells. The HI titre was determined as the reciprocal of the highest
serum dilution that inhibited 100% of hemagglutination.

Seroprotection was defined as having an HI titer $\geq$ 40.

### Details of the HI Data Processing

All data points are the result of two replicates; a geometric mean
titre was used to calculate the reported result:

$$result=10^{\frac{1}{2}((log(A)+log(B))}$$

where 'A' and 'B' are the two measured values.

All raw data points with a value of zero were converted to a value of
5 so that logarithms could be computed.

### Details of MN assay

### Details of the MN Data Processing

### Details of the ELISA assay

### Details of ELISA Data Processing

### Details of the ELLA assay

### Details of ELLA Data Processing

## Files Uploaded

`README.md`
:   This file. Uses *Markdown*, a text format that is directly
    readable or processed into a nicely formatted style. See:
    [*Markdown Guide*](https://www.markdownguide.org).

`README.pdf`
:   The output of the conversion of `README.md` to a PDF file via
    [`pandoc`](https://pandoc.org/).

`Incentive_QIV1_2_3-HI_Final_v1.0_2024-09-09.xlsx`
:   File containing the HI data for clinical trials known as QIV1,
    QIV2, and QIV3 (older adults, children and infants, respectively).

`Incentive_QIV1_2_3-HI_Final_v1.0_2024-09-09.csv`
:   File contains the same values as the Excel file above, but in
    long-format. This file is derived programatically from the
	Excel file. See: README_CSV.md.	

`Dictionary_QIV1_2_3-HI-assay.xlsx`
:   A data dictionary describing the contents of the file,
    `Incentive_QIV1_2_3-HI_Final_v1.0_2024-09-09.xlsx`.

`README_CSV.md`
:   A description of the CSV file,
    `Incentive_QIV1_2_3-HI_Final_v1.0_2024-09-09.csv`, including some
    basic R code to show how to read the file and to include some
    basic counts of the values contain within it.

`README_CSV.pdf`
:   The output of converting `README_CSV.md` to PDF via *pandoc*.

`Checksum.md5`
:   A file containing MD5 checksums of the files that are uploaded.

## Contact

For questions about this dataset, please contact:

```
Professor Rebecca Jane Cox
The Influenza Centre
Department of Clinical Science
University of Bergen
Bergen
Norway

Email: R.Cox@uib.no
Phone: +47 45242974
```
