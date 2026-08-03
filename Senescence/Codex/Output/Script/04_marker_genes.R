source("Codex/Output/Script/analysis_functions.R")

files <- vapply(1:8, function(i) {
  file.path(TABLE_DIR, sprintf("comparison_%d_%s_DE_results.csv", i, GROUP_LABELS[as.character(i)]))
}, character(1))
if (!all(file.exists(files))) stop("Run 02_per_comparison.R before marker visualization.")

requested <- c("PTCHD4", "CDKN1A", "CDKN2A", "PURPL", "GDF15", "MKI67", "LMNB1")
rows <- lapply(1:8, function(i) {
  z <- utils::read.csv(files[i], check.names = FALSE)
  is_marker <- z$Gene_name %in% requested | grepl("^MCM[[:alnum:]]*$", z$Gene_name)
  z <- z[is_marker, c("Gene_name", "log2FoldChange", "pvalue", "padj")]
  z$Comparison <- unname(GROUP_LABELS[as.character(i)])
  z
})
markers <- do.call(rbind, rows)
markers$neg_log10_pvalue <- -log10(pmax(markers$pvalue, .Machine$double.xmin))
markers$Gene_name <- factor(markers$Gene_name, levels = rev(sort(unique(markers$Gene_name))))
utils::write.csv(markers, file.path(TABLE_DIR, "marker_gene_statistics.csv"), row.names = FALSE)

p <- ggplot(markers, aes(Comparison, Gene_name, fill = log2FoldChange, size = neg_log10_pvalue)) +
  geom_point(shape = 21, color = "black") +
  scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B", midpoint = 0) +
  labs(title = "Senescence marker genes", x = NULL, y = NULL, fill = "log2FC", size = "-log10(p-value)") +
  theme_bw(base_size = 10) + theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggplot2::ggsave(file.path(PLOT_DIR, "marker_genes_dotplot.svg"), p, width = 11, height = 9)
writeLines(capture.output(sessionInfo()), file.path(REPORT_DIR, "04_marker_genes_sessionInfo.txt"))
