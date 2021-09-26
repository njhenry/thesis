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
chapter <- 'discussion'
chapter_type <- 'standalone'
doc_type <- 'pdf' # One of 'docx', 'pdf'
out_fp <- glue::glue(
  'C:/Users/nathenry/Dropbox/Writing/thesis/output/{chapter}_{Sys.Date()}.{doc_type}'
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
chapter_rmd_fp_base <- basename(chapter_rmd_fp)

# Set some output filenames
tex_dir <- file.path(repo, 'knitted_tex')
tex_dir_fp_base <- glue::glue('{chapter}.{doc_type}')

# Fix to identify xeLatex on Windows:
if((Sys.info()['sysname'] == 'Windows') & (Sys.which('xelatex')=='')){
  addpath <- 'C:/Users/nathenry/AppData/Local/Programs/MiKTeX/miktex/bin/x64'
  current_path <- Sys.getenv("PATH")
  Sys.setenv(PATH = paste(current_path, addpath, sep = ';'))
  if(Sys.which('xelatex')=='') stop("Still can't find xelatex")
}

## Compile Rmd to TEX and PDF using bookdown -------------------------------------------->

# Prepare input directory
setwd(dirname(chapter_rmd_fp))
tempfiles <- list.files('.', pattern='^_main.')
if(length(tempfiles) > 0) invisible(file.remove(tempfiles))

# Set up a config listing just this Rmd file
dummy_config <- list(
  'top-level-division' = 'section',
  'rmd_files'= chapter_rmd_fp_base
)
dummy_config_fp <- tempfile(fileext='.yaml')
yaml::write_yaml(dummy_config, file=dummy_config_fp)
pdf_args <- list(
  toc = FALSE, keep_tex = TRUE, latex_engine = 'xelatex',
  extra_dependencies = c('booktabs', 'doi', 'float', 'lipsum','makecell', 'url'),
  pandoc_args = c(
    glue::glue('--lua-filter={repo}/styles/scholarly_metadata.lua'),
    glue::glue('--lua-filter={repo}/styles/author_info_blocks.lua')
  )
)
compile_fun <- ifelse(doc_type=='pdf', bookdown::pdf_document2, bookdown::word_document2)
if(conf$v$preprint) pdf_args$extra_dependencies <- c(pdf_args$extra_dependencies, 'arxiv')
tex_dir_fp <- bookdown::render_book(
  input = basename(chapter_rmd_fp),
  output_format = do.call(compile_fun, args = pdf_args),
  output_file = tex_dir_fp_base,
  output_dir = tex_dir,
  config_file = dummy_config_fp
)

# Move compiled PDF file from repository to final output directory
invisible(file.copy(from = tex_dir_fp, to = out_fp, overwrite = TRUE))

# Clean up by deleting temporary config
invisible(file.remove(dummy_config_fp))
