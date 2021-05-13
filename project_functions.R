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


#' @title Config parser for hybrid R+TeX code
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

    # Public attribute to hold the YAML file list values
    v = NULL,

    # Method to instantiate a new DocConfig object. Reads and parses YAML file.
    initialize = function(config_path){
      # Check that the config path actually exists
      if(!file.exists(config_path)){
        stop(sprintf("Config filepath, %s, does not exist", config_path))
      }
      # Read config filepath
      config_vals <- yaml::read_yaml(config_path)
      # TODO: Ensure that all required headings are available
      # TODO: Resolve folder names in filepaths
      # Set the values as a public attribute
      self$v <- config_vals
      message("Config read successfully.")
      invisible(self)
    },

    # Print all values
    print = function(){
      message(sprintf("CONFIG: \n%s\n", str(self$v)))
      invisible(self)
    },

    # Method to write the config values to file
    write_to_file = function(out_file, verbose=TRUE){
      yaml::write_yaml(self$v, file=out_file)
      if(verbose) message(glue::glue("Config written to {out_file} successfully."))
      invisible(self)
    }
  )
)
