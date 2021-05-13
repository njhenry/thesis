## TEST: Can we knit an RNW document using data from the parent environment?

library(knitr)
library(tinytex)

# Set up config
config_fp <- '~/repos/thesis/testing/test_config.yaml'
rnw_fp <- '~/repos/thesis/testing/test_config_noexec.rnw'
tex_fp <- gsub('.rnw$', '.tex', rnw_fp)
conf <- yaml::read_yaml(config_fp)

knitr::knit(input = rnw_fp, output = tex_fp, envir = globalenv())
tinytex::latexmk(file=tex_fp)
