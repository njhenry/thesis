## #######################################################################################
##
## Setup and convenience functions for thesis writing
##
## Author: Nathaniel Henry, @njhenry
## Created: 7 May 2021
## Purpose: This file contains functions and class definitions that will be loaded in the
##   code that dynamically creates TEX documents.
##
## #######################################################################################

#' Get temporary file match patterns
#'
#' @description Get filepath patterns and suffixes of temporary files to remove
#'
#' @details For more information, see \code{\link{remove_temp_files}}
#'
#' @return A vector of filepath suffixes
get_temp_file_patterns <- function(){
  fps <- c(
    '.bbl$','.bcf$','-blx.bib$','-concordance.tex$','.log$','.run.xml$','.gz$','.pdf$'
  )
  return(fps)
}


#' Remove temporary files
#'
#' @description Remove temporary files created by `knitr` and `tinytex` from a directory
#'
#' @param dir [char, default NULL] Directory to clean. If `NULL` (the default), cleans
#'   the current directory
#' @param match_patterns [char, default NULL] Match patterns to remove from the directory.
#'   If `NULL` (the default), pulls from \code{\link{get_temp_file_patterns}}
#'
#' @return Invisible (removes all matching files)
remove_temp_files <- function(dir = NULL, match_patterns = NULL){
  # Set defaults
  if(is.null(match_patterns)) match_patterns <- get_temp_file_patterns()
  if(is.null(dir)) dir <- getwd()
  # List files to remove
  rm_fps <- list.files(
    path = dir, pattern = paste(match_patterns, collapse='|'),
    ignore.case = TRUE, full.names = TRUE, recursive = FALSE
  )
  # Remove them
  if(length(rm_fps) > 0) unlink(rm_fps)
  invisible()
}


#' Load a single dataset
#'
#' @description Convenience function for loading a filepath based on extension
#'
#' @importFrom data.table fread
#' @importFrom yaml read_yaml
#'
#' @param filepath File location of dataset. Function will error if filepath does not
#'   exist
#'
#' @return Dataset in data.table form, or list form in case of YAML files
#'
load_dataset_from_file <- function(filepath){
  if(!file.exists(filepath)) stop("Path ", filepath, " does not exist!")
  # Load file based on extension
  fp_lower <- tolower(filepath)
  if(grepl('\\.yaml$', fp_lower) | grepl('\\.yml$', fp_lower)){
    dataset <- yaml::read_yaml(filepath)
  } else {
    dataset <- data.table::fread(filepath)
  }
  return(dataset)
}


#' Load list of datasets
#'
#' @description Load all files from a named list and return as a named list of data.tables
#'
#' @param fp_list Named list of file paths to read
#' @return Named list of datasets
load_dataset_list <- function(fp_list){
  if(!"list" %in% class(fp_list)) stop("Input filepath list is not of type 'list'")
  data_list <- lapply(fp_list, load_dataset_from_file)
  names(data_list) <- names(fp_list)
  return(data_list)
}


#' Match chapter name to file
#'
#' @description Match a chapter name to a markdown file within the project repository
#'
#' @importFrom glue glue
#'
#' @param chapter_name [char] Name of the chapter. This function will search for a file
#'   matching "{chapter_name}.Rmd" (case-insensitive)
#' @param repo [char] Path to the top-level directory containing the thesis repository
#' @param check_subdirs [char, default c('', raw_rmd', 'testing')] Which subdirectories
#'   should be checked for the Rmd file?
#'
#' @return Full path to the chapter file
#'
match_chapter_to_file <- function(
  chapter_name, repo, check_subdirs = c('', 'raw_rmd', 'testing')
){
  # Check repo exists
  if(!dir.exists(repo)) stop(glue::glue("Repository {repo} does not exist"))
  # Iterate through directories to search for file
  check_dirs <- file.path(repo, check_subdirs)
  for(check_dir in check_dirs){
    match_files <- list.files(
      check_dir,
      pattern = glue::glue('^{chapter_name}.Rmd$'),
      ignore.case = TRUE,
      full.names = TRUE
    )
    if(length(match_files) > 0) return(match_files[1])
  }
  # Pattern not found in any subdirectory
  stop(
    "File ", chapter_name ,".Rmd not found. Directories checked:\n - ",
    paste(check_dirs, collapse = '\n - ')
  )
}


#' Config parser for hybrid Rmd+TeX code
#'
#' @description An R6 class with convenience functions for loading and validating a
#'   configuration file in YAML format
#'
#' @docType class
#' @importFrom R6 R6Class
#' @importFrom glue glue
#' @importFrom yaml read_yaml
#' @export
#'
#' @return Object of \code{\link{R6Class}} which loads and stores settings to be used for
#'   document creation.
#'
#' @param config_path Full path to config YAML file.
#' @section Public methods:
#' \describe{
#'   \item{\code{new(config_path)}}{
#'     Initializes a new config object that pulls from a YAML file specified by
#'     `config_path`. Resolves all file paths and checks that certain headings exist.
#'   }
#'   \item{\code{print()}}{Prints the full config object with headings.}
#'   \item{\code{write_to_file(out_fp)}}{Writes config values to a specified YAML file.}
#' }
#' @section Public attributes:
#' \describe{
#'   \item{v}{Holds the values read in from the YAML file as a list of lists}
#' }
#'
DocConfig <- R6::R6Class(
  "DocConfig",
  ## DocConfig private attributes and methods
  private = list(),

  ## DocConfig public attributes and methods
  public = list(

    ## 1) Reserved public methods ------------------------------------------------------->

    # Method to instantiate a new DocConfig object. Reads and parses YAML file.
    # Call this method as: `my_config <- DocConfig.new(config_path='/a/path.yaml')`
    initialize = function(config_path){
      # Check that the config path actually exists
      if(!file.exists(config_path)){
        stop(sprintf("Config filepath, %s, does not exist", config_path))
      }
      # Read config filepath
      config_vals <- yaml::read_yaml(config_path)
      # Ensure that all required headings are available
      self$check_required_keys(config_vals)
      # Resolve folder names in filepaths
      config_vals <- self$resolve_filepaths(
        resolve_list = config_vals,
        replace_list = config_vals$dirs
      )
      # Set the values as a public attribute
      self$v <- config_vals
      message("Config read successfully.")
      invisible(self)
    },

    # Print all values
    print = function(){
      message(sprintf("CONFIG: \n%s\n", str(self$v)))
      invisible()
    },

    ## 2) Public attributes ------------------------------------------------------------->

    # YAML file list values
    v = NULL,

    # Required top-level keys in the config YAML file
    required_keys = c('load_libraries', 'dirs', 'graphics_fps', 'data_fps'),

    ## 3) Non-reserved public methods --------------------------------------------------->

    # Check that a config list contains all required top-level keys
    check_required_keys = function(config_list){
      config_keys <- names(config_list)
      missing_keys <- setdiff(self$required_keys, config_keys)
      if(length(missing_keys) > 0){
        stop("Missing config keys: ", paste(missing_keys, collapse=', '))
      }
      invisible()
    },

    # Resolve all file paths that refer to '{keys}' in the config
    resolve_filepaths = function(resolve_list, replace_list){
      # Sub-function to apply across all list items
      replace_fun <- function(check_item, replace_list){
        # Only act on character vectors that include a "{replace_key}" sequence
        if(is.null(check_item)) return(check_item)
        if(all(is.na(check_item))) return(check_item)
        if(!'character' %in% class(check_item)) return(check_item)
        # Check each value
        key_vec <- names(replace_list)
        replace_val_match <- paste0('\\{[', paste(key_vec, collapse='|'), ']+\\}')
        vec_len <- length(check_item)
        return_vec <- rep(as.character(NA), vec_len)
        for(ii in 1:vec_len){
          if(grepl(replace_val_match, check_item[ii])){
            return_vec[ii] <- glue::glue(check_item[ii], .envir=replace_list)
          } else {
            return_vec[ii] <- check_item[ii]
          }
        }
        # Return item with any needed replacements
        return(return_vec)
      }
      return(rapply(resolve_list, replace_fun, how='replace', replace_list=replace_list))
    },

    # Method to write the config values to file
    write_to_file = function(out_file, verbose=TRUE){
      yaml::write_yaml(self$v, file=out_file)
      if(verbose) message(glue::glue("Config written to {out_file} successfully."))
      invisible()
    }
  )
)
