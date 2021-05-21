## #######################################################################################
##
## COMPILE A STANDALONE CHAPTER
##
## AUTHOR: Nathaniel Henry, Github @njhenry
## CREATED: 20 May 2021
## PURPOSE: Compile TEX and PDF documents for a single thesis chapter
##
## NOTES:
##  - This script expects three input arguments:
##     * Path to a config YAML file
##     * Chapter title
##     * Path where the output PDF file should be saved
##    of the standalone thesis chapter
##  - It matches two files which should be located in this repository:
##     * `./raw_rnw/HEADER_standalone.Rnw`, templating the TEX header and styling
##     * `./raw_rnw/<chapter>.Rnw`, templating the chapter TEX
##  - Script execution outline:
##     1) Load config file and helper functions
##     2) Set graphics filepaths and load datasets corresponding to this chapter
##     3) Knit chapter content, creating a TEX stub
##     4) Knit full chapter, creating a TEX document that contains the stub from (3) with
##        additional styling information. This document will be written to the
##        `./knitted_tex` subdirectory.
##     5) Compile PDF and save to the specified output file
##
## #######################################################################################


## SETUP -------------------------------------------------------------------------------->

# Script arguments
# TODO: Convert to CLI
conf_fp <- '~/repos/thesis/config.yaml'
chapter <- 'test_chapter'
pdf_out_fp <- paste0(
  '~/Documents/Dropbox/Writing/thesis_resources/output/',chapter,'_',Sys.Date(),'.pdf'
)

# Load config, required packages, and helper functions
repo <- yaml::read_yaml(conf_fp)$dirs$repo
source(file.path(repo, 'project_functions.R'))
conf <- DocConfig$new(config_path = file.path(conf_fp))
invisible(lapply(conf$v$load_libraries, library, character.only=TRUE))

# Get datasets and graphics filepaths for this chapter
data_list <- load_dataset_list(conf$v$data_fps[[chapter]])
graphics_fps <- conf$v$graphics_fps[[chapter]]


## KNIT CHAPTER CONTENTS AND COMPILE PDF ------------------------------------------------>

# Set RNW and TEX input and intermediate output filepaths
header_rnw_fp <- glue::glue('{repo}/raw_rnw/HEADER_standalone.Rnw')
stub_rnw_fp <- glue::glue('{repo}/raw_rnw/{chapter}.Rnw')
stub_tex_fp <- glue::glue('{repo}/raw_rnw/{chapter}.tex')
full_tex_fp <- glue::glue('{repo}/knitted_tex/{chapter}.tex')

# Knit stub RNW to TEX
knitr::knit(input = stub_rnw_fp, output = stub_tex_fp, envir = globalenv())

# Knit header RNW + TEX stub -> full TEX chapter
knitr::knit(input = header_rnw_fp, output = full_tex_fp, envir = globalenv())

# Compile knitted TEX chapter -> output PDF
tinytex::latexmk(file=full_tex_fp, pdf_file = pdf_out_fp)
