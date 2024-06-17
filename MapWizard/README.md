#  MapWizard

This is a POC for providing sematnics based data mapping suggestion.  

## Problem
Suppose you have several CSV files with data, and you need to do some ETL type of work on the files. Maybe you'd like to join some of them and combine (union) others - daily mundane work of a Data Analyst. The tool does semantic analysis of the data in each column of each file and suggests the columns with similar content even if they are named differently in different files.  
As an example, you can use (https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/51B6NK)[CDISC-SDTM sample study] dataset from Harvard Dataverse.

Here I intentionally modified some column names so that they're different. And yet the tool can identify and color code the columns as mapping candidates. Some mappings are false positives as their data is not distinct enough.

![alt text](https://github.com/iliasaz/MapWizard/blob/main/MapWizard/screenshot.png?raw=true)

The tool uses Apple's [NLEmbedding API](https://developer.apple.com/documentation/naturallanguage/nlembedding)


