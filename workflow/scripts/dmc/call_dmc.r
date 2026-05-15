suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(DSS))
suppressPackageStartupMessages(library(data.table))

option_list <- list(
  make_option(c("--dml"), type = "character", help = "dml test object"),
  make_option(c("--p-value","-p"), type = "double", help = "p-value threshold"),
  make_option(c("--delta", "-d"), type = "double", help = "delta threshold"),
  make_option(c("--output", "-o"), type = "character", help = "Output DMC RDS file"),
  make_option(c("--summary"), type = "character", help = "Output summary TSV file")
)


call_dmc <- function(dml, p_value, delta) {
    return(
        callDML(
            dml, 
            p.threshold = p_value,
            delta = delta
        )
    )
}

prepare_summary <- function(dmcs, p_value, delta) {
    return (
        data.table(
            method = "DSS",
            p_threshold = p_value,
            delta = delta,
            n_dmcs = nrow(dmcs),
            mean_effect_size = mean(abs(dmcs$diff), na.rm = TRUE),
            median_effect_size = median(abs(dmcs$diff), na.rm = TRUE)
        )
    )
}

opt <- parse_args(OptionParser(option_list = option_list))

dml_test <-readRDS(opt$dml)
p_treshold <-opt$p
delta_treshold <-opt$delta

dmcs <- call_dmc(
    dml_test,
    p_treshold,
    delta_treshold
)
summary_dt <- prepare_summary(
    dmcs,
    p_treshold,
    delta_treshold
)

saveRDS(dmcs, opt$output)
fwrite(summary_dt, opt$summary, sep = "\t")


