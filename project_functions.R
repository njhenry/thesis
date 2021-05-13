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


