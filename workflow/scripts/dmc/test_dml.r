suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(DSS))
suppressPackageStartupMessages(library(data.table))

option_list <- list(
  make_option(c("--bs"), type = "character", help = "BS object"),
  make_option(c("--sample-info"), type = "character", help = "Samples metadata"),
  make_option(c("--output", "-o"), type = "character", help = "Output RDS file"),
  make_option(c("--threads", "-t"), type = "integer", default = 1, help = "Threads"),
  make_option(c("--smoothing"), action = "store_true", default = TRUE, help = "Smoothing")
)

test_dml <- function(BS_filtered, group1, group2, cores, smoothing) {
    return (
        DMLtest(BS_filtered,
            group1 = group1,
            group2 = group2,
            ncores = cores, 
            smoothing = smoothing
        )
    )
}

opt <- parse_args(OptionParser(option_list = option_list))

BS_filtered <-readRDS(opt[['bs']])
sample_info <-fread(opt[["sample-info"]])

group1 <- sample_info[condition == "normal", SRA]
group2 <- sample_info[condition == "cancer", SRA]

dmlTest <- test_dml(
    BS_filtered,
    group1,
    group2,
    opt$threads,
    opt$smoothing
)

dir.create(dirname(opt$output), recursive = TRUE, showWarnings = FALSE)
saveRDS(dmlTest, opt$output)