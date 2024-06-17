#  MapWizard

This is a POC for providing semantics based data mapping suggestions.  

## Problem
Suppose you have several CSV files with data, and you would like to do some ETL type of work on the files. Maybe you'd like to join some of them and combine (union) others - a daily mundane work of a Data Analyst. The tool does semantic analysis of the data in each column of each file and suggests the columns with similar content even if they are named differently in different files.  
As an example, you can use [CDISC-SDTM sample study](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/51B6NK) dataset from Harvard Dataverse.

Here I intentionally modified some the column names so that they're different. And yet the tool can identify and color code the columns as mapping candidates. Some mappings are false positives as their data is not distinct enough.

![alt text](https://github.com/iliasaz/MapWizard/blob/main/screenshot.png?raw=true)

The tool uses Apple's [NLEmbedding API](https://developer.apple.com/documentation/naturallanguage/nlembedding)


