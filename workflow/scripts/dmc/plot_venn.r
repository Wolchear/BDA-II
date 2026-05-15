suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(ggforce))

option_list <- list(
  make_option(c("--dss"), type = "character", help = "DSS DMC RDS"),
  make_option(c("--wilcoxon"), type = "character", help = "Wilcoxon DMC RDS"),
  make_option(c("--output", "-o"), type = "character", help = "Output PDF")
)

opt <- parse_args(OptionParser(option_list = option_list))

dss_dmcs <- as.data.table(readRDS(opt$dss))
wilcox_dmcs <- as.data.table(readRDS(opt$wilcoxon))

dss_ids <- paste(dss_dmcs$chr, dss_dmcs$pos, sep = ":")
wilcox_ids <- paste(wilcox_dmcs$chr, wilcox_dmcs$pos, sep = ":")

n_dss <- length(dss_ids)
n_wilcox <- length(wilcox_ids)
n_overlap <- length(intersect(dss_ids, wilcox_ids))

plot_df <- data.frame(
    x0 = c(0, 1),
    y0 = c(0, 0),
    r = c(1, 1),
    method = c("DSS", "Wilcoxon")
)

p <- ggplot() +
    geom_circle(data = plot_df, aes(x0 = x0, y0 = y0, r = r, fill = method), alpha = 0.35) +
    annotate("text", x = -0.45, y = 0, label = n_dss - n_overlap, size = 6) +
    annotate("text", x = 0.5, y = 0, label = n_overlap, size = 6) +
    annotate("text", x = 1.45, y = 0, label = n_wilcox - n_overlap, size = 6) +
    annotate("text", x = -0.5, y = 1.1, label = "DSS", size = 5) +
    annotate("text", x = 1.5, y = 1.1, label = "Wilcoxon", size = 5) +
    coord_fixed() +
    theme_void()

ggsave(opt$output, p, width = 6, height = 5)