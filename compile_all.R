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

rm(list=ls())

## SETUP -------------------------------------------------------------------------------->

# Script arguments
conf_fp <- '~/repos/thesis/config.yaml'
out_fp <- glue::glue(
  'C:/Users/nathenry/Dropbox/Writing/thesis/output/full_thesis_{Sys.Date()}.pdf'
)

# Load config, required packages, and helper functions
repo <- yaml::read_yaml(conf_fp)$dirs$repo
source(file.path(repo, 'project_functions.R'))
conf <- DocConfig$new(config_path = file.path(conf_fp))
invisible(lapply(conf$v$load_libraries, library, character.only=TRUE))

# Get datasets and graphics filepaths across all chapters
data_fps <- conf$v$data_fps
data_list <- lapply(data_fps, load_dataset_list)
names(data_list) <- names(data_fps)
graphics_fps <- conf$v$graphics_fps

# Set some output filenames
tex_dir <- file.path(repo, 'knitted_tex')
tex_dir_fp_base <- 'full_thesis.pdf'

# Fix to identify xeLatex on Windows:
if((Sys.info()['sysname'] == 'Windows') & (Sys.which('xelatex')=='')){
  addpath <- 'C:/Users/nathenry/AppData/Local/Programs/MiKTeX/miktex/bin/x64'
  current_path <- Sys.getenv("PATH")
  Sys.setenv(PATH = paste(current_path, addpath, sep = ';'))
  if(Sys.which('xelatex')=='') stop("Still can't find xelatex")
}


## Compile Rmd to TEX and PDF using bookdown -------------------------------------------->

# Prepare input directory
setwd(file.path(dirname(conf_fp), 'joint_book'))
tempfiles <- list.files('.', pattern='^_main.')
if(length(tempfiles) > 0) invisible(file.remove(tempfiles))
Sys.setenv(RSTUDIO_PDFLATEX = "latexmk")

# Set up a config listing just this Rmd file
# Dependencies are now defined as part of the 'ociamthesis' class
pdf_args <- list(
  keep_tex = TRUE, latex_engine = 'xelatex', citation_package = 'biblatex',
  includes = list(
    in_header = 'ox_thesis_header.tex',
    before_body = 'ox_thesis_title_page.tex'
  ),
  toc = FALSE, number_sections = TRUE, lot = TRUE, lof = TRUE
)
tex_dir_fp <- bookdown::render_book(
  output_format = do.call('pdf_book', args = pdf_args),
  output_file = tex_dir_fp_base,
  output_dir = tex_dir
)
