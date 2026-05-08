suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(bsseq))


option_list <- list(
  make_option(c("--meth"), type = "character", help = "Methylation matrix file"),
  make_option(c("--cov"), type = "character", help = "Coverage matrix file"),
  make_option(c("--sample-info"), type = "character", help = "Samples metadata"),
  make_option(c("--output", "-o"), type = "character", help = "Output RDS file"),
  make_option(c("--cov-filter"), type = "integer", default = 10, help = "Minimum coverage per cpg for filtering")
)

get_bs <- function(meth, cov, sample_info) {
    sample_cols <- setdiff(names(meth), c("chrom", "start", "end"))
    sample_info <- as.data.frame(sample_info)
    sample_info <- sample_info[match(sample_cols, sample_info$SRA), ]
    chr <- meth$chrom
    pos <- meth$start

    meth_matrix <- as.matrix(meth[, ..sample_cols])
    Cov_matrix <- as.matrix(cov[, ..sample_cols])

    M_matrix <- round(meth_matrix * Cov_matrix)

    M_matrix[is.na(M_matrix)] <- 0
    Cov_matrix[is.na(Cov_matrix)] <- 0

    colnames(M_matrix) <- sample_cols
    colnames(Cov_matrix) <- sample_cols

    BS <- BSseq(
            chr = chr,
            pos = pos,
            M = M_matrix,
            Cov = Cov_matrix,
            sampleNames = sample_cols
        )
    pData(BS) <- sample_info
    rownames(pData(BS)) <- sample_info$SRA

    return (BS)
}

filter_bs <- function(BS, cov_filter) {
    cov_matrix <- getCoverage(BS)

    samples_covered <- rowSums(cov_matrix >= cov_filter, na.rm = TRUE)
    keep_cpgs <- samples_covered == ncol(cov_matrix)

    return(BS[keep_cpgs])
}

opt <- parse_args(OptionParser(option_list = option_list))

methylation_dt <- fread(opt$meth)
coverage_dt <- fread(opt$cov)
sample_info <-fread(opt[["sample-info"]])

BS <- get_bs(methylation_dt, coverage_dt, sample_info)

BS_filtered <- filter_bs(BS, opt[["cov-filter"]])

dir.create(dirname(opt$output), recursive = TRUE, showWarnings = FALSE)
saveRDS(BS_filtered, opt$output)