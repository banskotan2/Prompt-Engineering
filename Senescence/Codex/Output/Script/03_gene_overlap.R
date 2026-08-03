source("Codex/Output/Script/analysis_functions.R")

files <- vapply(1:8, function(i) {
  file.path(TABLE_DIR, sprintf("comparison_%d_%s_DE_results.csv", i, GROUP_LABELS[as.character(i)]))
}, character(1))
if (!all(file.exists(files))) stop("Run 02_per_comparison.R before overlap analysis.")
tabs <- lapply(files, utils::read.csv, check.names = FALSE)
names(tabs) <- unname(GROUP_LABELS)

make_sets <- function(direction) {
  lapply(tabs, function(z) unique(z$Gene_name[
    !is.na(z$padj) & z$padj < 0.05 &
      if (direction == "up") z$log2FoldChange > 0 else z$log2FoldChange < 0
  ]))
}

for (direction in c("up", "down")) {
  sets <- make_sets(direction)
  membership <- UpSetR::fromList(sets)
  svg_file <- file.path(PLOT_DIR, paste0("overlap_", direction, "_UpSet.svg"))
  if (nrow(membership) == 0) {
    placeholder_svg(svg_file, paste("FDR < 0.05", direction, "genes"), "No significant genes in any comparison")
  } else {
    safe_svg(svg_file, 12, 7, {
      # UpSetR applies sort keys sequentially; the last key is primary.
      # Putting degree last places 8-way, then 7-way, then lower overlaps left-to-right.
      print(UpSetR::upset(
        membership, sets = names(sets), nsets = 8, nintersects = 40,
        order.by = c("freq", "degree"), decreasing = c(TRUE, TRUE), keep.order = TRUE,
        mainbar.y.label = paste("Intersection size:", direction),
        sets.x.label = "Significant genes"
      ))
    })
  }
  if (!file.exists(svg_file) || file.info(svg_file)$size < 1000) {
    stop("UpSet SVG is missing or visually empty: ", svg_file)
  }
  common <- Reduce(intersect, sets)
  utils::write.csv(
    data.frame(Gene_name = sort(common)),
    file.path(TABLE_DIR, paste0("overlap_all_comparisons_", direction, ".csv")),
    row.names = FALSE
  )
  common_rows <- do.call(rbind, lapply(names(tabs), function(nm) {
    z <- tabs[[nm]]
    z <- z[z$Gene_name %in% common, c("Gene_name", "log2FoldChange", "pvalue", "padj")]
    z$Comparison <- nm
    z
  }))
  utils::write.csv(common_rows, file.path(TABLE_DIR, paste0("overlap_all_comparisons_", direction, "_statistics.csv")), row.names = FALSE)
  dot_file <- file.path(PLOT_DIR, paste0("overlap_all_comparisons_", direction, "_dotplot.svg"))
  if (nrow(common_rows) == 0) {
    placeholder_svg(dot_file, paste("Genes", direction, "in all comparisons"), "No genes met the criterion across all eight comparisons")
  } else {
    common_rows$neg_log10_pvalue <- -log10(pmax(common_rows$pvalue, .Machine$double.xmin))
    p <- ggplot(common_rows, aes(Comparison, Gene_name, fill = log2FoldChange, size = neg_log10_pvalue)) +
      geom_point(shape = 21, color = "black") +
      scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B", midpoint = 0) +
      labs(title = paste("Genes", direction, "in all comparisons"), x = NULL, y = NULL, size = "-log10(p-value)", fill = "log2FC") +
      theme_bw(base_size = 10) + theme(axis.text.x = element_text(angle = 45, hjust = 1))
    ggplot2::ggsave(dot_file, p, width = 11, height = max(5, 0.25 * length(common) + 2), limitsize = FALSE)
  }
}
writeLines(capture.output(sessionInfo()), file.path(REPORT_DIR, "03_gene_overlap_sessionInfo.txt"))
