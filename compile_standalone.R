## #######################################################################################
##
## COMPILE A STANDALONE CHAPTER
##
## AUTHOR: Nathaniel Henry, Github @njhenry
## CREATED: 21 May 2021
## PURPOSE: Compile TEX and PDF documents for a single thesis chapter
##
## NOTES:
##  - This script expects three input arguments:
##     * Path to config file
##     * Chapter name (eg. 'test_chapter'). This name will be matched to a Rmd file in
##       the repository's './raw_rmd' folder or, if not found there, in './testing'
##     * Path where the output PDF file should be saved
##  - Script execution outline:
##     1) Load config file and helper functions
##     2) Set graphics filepaths and load datasets corresponding to this chapter
##     3) Knit chapter content into a TEX file (saved in './knitted_tex') and compile into
##        PDF format (saved to the specified output file)
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

# Find the chapter filepath within the repository
chapter_rmd_fp <- match_chapter_to_file(chapter_name = chapter, repo = repo)

# Set some output filenames
tex_dir <- file.path(repo, 'knitted_tex')
tex_dir_fp_base <- glue::glue('{chapter}.pdf')

## Compile Rmd to TEX and PDF using bookdown -------------------------------------------->

tex_dir_fp <- bookdown::render_book(
  input = chapter_rmd_fp,
  output_format = bookdown::pdf_book(
    keep_tex=TRUE,
    base_format=rmarkdown::pdf_document,
    toc=FALSE
  ),
  output_file = tex_dir_fp_base,
  output_dir = tex_dir
)
# Move compiled PDF file from repository to final output directory
invisible(file.rename(from = tex_dir_fp, to = pdf_out_fp))
