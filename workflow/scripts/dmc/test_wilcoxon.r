suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(bsseq))
suppressPackageStartupMessages(library(data.table))


option_list <- list(
  make_option(c("--bs"), type = "character", help = "BS object"),
  make_option(c("--sample-info"), type = "character", help = "Samples metadata"),
  make_option(c("--output", "-o"), type = "character", help = "Output RDS file"),
  make_option(c("--threads", "-t"), type = "integer", default = 1, help = "Threads"),
  make_option(c("--smoothing"), action = "store_true", default = TRUE, help = "Smoothing")
)

get_matix <- function(bs) {
    M_matrix   <- getCoverage(bs, type = "M")
    Cov_matrix <- getCoverage(bs, type = "Cov")

    meth_matrix <- M_matrix / Cov_matrix
    meth_matrix[Cov_matrix == 0] <- NA
    return(meth_matrix)
}

test_wlcoxon <- function(bs, meth_matrix, group1, group2) {
    pvals <- apply(meth_matrix, 1, function(row) {
                    x <- as.numeric(row[group1])
                    y <- as.numeric(row[group2])
                    wilcox.test(x, y, exact = FALSE)$p.value
            })
    

    diff <- rowMeans(meth_matrix[, group2, drop = FALSE], na.rm = TRUE) -
            rowMeans(meth_matrix[, group1, drop = FALSE], na.rm = TRUE)

    return(
        data.table(
            chr = as.character(seqnames(bs)),
            pos = start(bs),
            pvalue = pvals,
            padj = p.adjust(pvals, method = "BH"),
            diff = diff
        )
    )
}

opt <- parse_args(OptionParser(option_list = option_list))

BS_filtered <-readRDS(opt[['bs']])
sample_info <-fread(opt[["sample-info"]])

group1 <- sample_info[condition == "normal", SRA]
group2 <- sample_info[condition == "cancer", SRA]

meth_matrix <- get_matix(BS_filtered)

wlcoxon_test <- test_wlcoxon(
    BS_filtered,
    meth_matrix,
    group1,
    group2
)

dir.create(dirname(opt$output), recursive = TRUE, showWarnings = FALSE)
saveRDS(wlcoxon_test, opt$output)