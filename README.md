# Nathaniel Henry DPhil thesis code

This repository contains the knitR/LaTeX markup for my doctoral thesis.


## Contact info

- *Author:* Nathaniel Henry
- *Github:* [`@njhenry`](https://github.com/njhenry)
- *Email:* nat.henry7@gmail.com


## Repository structure

This repository structures my doctoral thesis. Each sub-directory (except for
`./testing`) contains the text for one chapter, written in LaTeX with knitR code
blocks. The top level of the repository contains project settings and resources
used across chapters, including:

- `project_functions.R`: Setup and convenience functions used in the knitR code
  blocks.
- `config.yaml`: A tiered list containing global variables to use across
  chapters. Loaded into an R4 object named CONF that can be called in knitR code
  blocks.
- `thesis.Rproj`: Rstudio settings


## Software

This thesis was written using RStudio version 1.4.1103, executing R version 
4.0.5. The packages required to execute knitR code are listed as 
'load_libraries' in `config.yaml`.
