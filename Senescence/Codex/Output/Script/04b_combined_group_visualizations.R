options(stringsAsFactors = FALSE)

suppressPackageStartupMessages({
  library(DESeq2)
  library(ggplot2)
  library(ggrepel)
  library(patchwork)
  library(ComplexHeatmap)
  library(circlize)
  library(grid)
})

output_dir <- "Codex/Output"
plot_dir <- file.path(output_dir, "Plot")
table_dir <- file.path(output_dir, "Table")
report_dir <- file.path(output_dir, "Report")

group_labels <- c(
  "HAEC_IR", "HUVEC_IR", "IMR90_IR", "IMR90_RE",
  "WI38_Dox", "WI38_HRAS", "WI38_IR", "WI38_RE"
)
prefixes <- sprintf("comparison_%d_%s", seq_along(group_labels), group_labels)

pca_plots <- vector("list", length(prefixes))
heatmap_inputs <- vector("list", length(prefixes))
pca_coordinates <- vector("list", length(prefixes))
selected_gene_tables <- vector("list", length(prefixes))

for (i in seq_along(prefixes)) {
  prefix <- prefixes[i]
  message("Preparing combined panels for ", prefix)
  dds_file <- file.path(table_dir, paste0(prefix, "_dds.rds"))
  result_file <- file.path(table_dir, paste0(prefix, "_DE_results.csv"))
  if (!file.exists(dds_file) || !file.exists(result_file)) {
    stop("Missing comparison output for ", prefix)
  }

  dds <- readRDS(dds_file)
  vsd <- DESeq2::vst(dds, blind = FALSE)
  metadata <- as.data.frame(SummarizedExperiment::colData(dds))

  pc <- DESeq2::plotPCA(vsd, intgroup = "Condition", returnData = TRUE)
  percent_var <- round(100 * attr(pc, "percentVar"))
  pc$Sample <- rownames(pc)
  pc$Comparison <- group_labels[i]
  pca_coordinates[[i]] <- pc
  pca_plots[[i]] <- ggplot(pc, aes(PC1, PC2, color = Condition, label = Sample)) +
    geom_point(size = 2.7) +
    ggrepel::geom_text_repel(size = 2.1, max.overlaps = Inf, min.segment.length = 0) +
    scale_color_manual(values = c(Control = "#2166AC", Senescent = "#B2182B")) +
    labs(
      title = group_labels[i],
      x = sprintf("PC1 (%d%%)", percent_var[1]),
      y = sprintf("PC2 (%d%%)", percent_var[2])
    ) +
    theme_bw(base_size = 9) +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold"),
      legend.title = element_blank()
    )

  results <- utils::read.csv(result_file, check.names = FALSE)
  ranked <- results[is.finite(results$pvalue), , drop = FALSE]
  ranked <- ranked[order(ranked$pvalue), , drop = FALSE]
  ranked <- ranked[!duplicated(ranked$Gene_stable_ID), , drop = FALSE]
  selected <- head(ranked, 50)
  genes <- selected$Gene_stable_ID
  genes <- genes[genes %in% rownames(vsd)]
  if (length(genes) < 2) stop("Too few finite genes for ", prefix)

  mat <- SummarizedExperiment::assay(vsd)[genes, , drop = FALSE]
  mat <- t(scale(t(mat)))
  mat[!is.finite(mat)] <- 0
  symbols <- selected$Gene_name[match(genes, selected$Gene_stable_ID)]
  rownames(mat) <- make.unique(symbols)
  colnames(mat) <- metadata$Filename[match(colnames(mat), rownames(metadata))]
  heatmap_inputs[[i]] <- list(
    matrix = mat,
    condition = as.character(metadata$Condition),
    label = group_labels[i]
  )
  selected$Comparison <- group_labels[i]
  selected$Rank <- seq_len(nrow(selected))
  selected_gene_tables[[i]] <- selected

  rm(dds, vsd, metadata, results, ranked, selected, mat)
  invisible(gc())
}

combined_pca <- patchwork::wrap_plots(
  pca_plots,
  ncol = 4,
  nrow = 2,
  guides = "collect"
) +
  patchwork::plot_annotation(title = "PCA by senescence comparison") &
  theme(legend.position = "bottom")
ggplot2::ggsave(
  file.path(plot_dir, "combined_group_PCA_2x4.svg"),
  combined_pca,
  width = 20,
  height = 10
)
utils::write.csv(
  do.call(rbind, pca_coordinates),
  file.path(table_dir, "combined_group_PCA_coordinates.csv"),
  row.names = FALSE
)
utils::write.csv(
  do.call(rbind, selected_gene_tables),
  file.path(table_dir, "combined_heatmap_selected_genes.csv"),
  row.names = FALSE
)

condition_colors <- c(Control = "#2166AC", Senescent = "#B2182B")
z_colors <- circlize::colorRamp2(c(-2, 0, 2), c("navy", "white", "firebrick3"))
heatmap_file <- file.path(plot_dir, "combined_comparison_heatmaps_2x4.svg")
grDevices::svg(heatmap_file, width = 22, height = 16, onefile = TRUE)
grid::grid.newpage()
layout <- grid::grid.layout(
  nrow = 3,
  ncol = 5,
  widths = grid::unit(c(1, 1, 1, 1, 0.28), "null"),
  heights = grid::unit(c(0.08, 1, 1), "null")
)
grid::pushViewport(grid::viewport(layout = layout))
grid::pushViewport(grid::viewport(layout.pos.row = 1, layout.pos.col = 1:5))
grid::grid.text(
  "Top 50 p-value-ranked genes per comparison",
  gp = grid::gpar(fontsize = 16, fontface = "bold")
)
grid::popViewport()

for (i in seq_along(heatmap_inputs)) {
  x <- heatmap_inputs[[i]]
  annotation <- ComplexHeatmap::HeatmapAnnotation(
    Condition = x$condition,
    col = list(Condition = condition_colors),
    show_annotation_name = FALSE,
    show_legend = FALSE
  )
  heatmap <- ComplexHeatmap::Heatmap(
    x$matrix,
    name = paste0("z_", i),
    col = z_colors,
    top_annotation = annotation,
    cluster_rows = TRUE,
    cluster_columns = TRUE,
    show_heatmap_legend = FALSE,
    show_row_names = TRUE,
    show_column_names = TRUE,
    row_names_gp = grid::gpar(fontsize = 4),
    column_names_gp = grid::gpar(fontsize = 5),
    column_names_rot = 45,
    column_title = x$label,
    column_title_gp = grid::gpar(fontsize = 10, fontface = "bold"),
    use_raster = TRUE,
    raster_quality = 2
  )
  panel_row <- ceiling(i / 4) + 1
  panel_col <- ((i - 1) %% 4) + 1
  grid::pushViewport(grid::viewport(layout.pos.row = panel_row, layout.pos.col = panel_col))
  ComplexHeatmap::draw(
    heatmap,
    newpage = FALSE,
    show_heatmap_legend = FALSE,
    show_annotation_legend = FALSE,
    padding = grid::unit(c(2, 2, 2, 2), "mm")
  )
  grid::popViewport()
}

legends <- ComplexHeatmap::packLegend(
  ComplexHeatmap::Legend(
    title = "Row z-score",
    col_fun = z_colors,
    title_gp = grid::gpar(fontsize = 9, fontface = "bold"),
    labels_gp = grid::gpar(fontsize = 8)
  ),
  ComplexHeatmap::Legend(
    title = "Condition",
    labels = names(condition_colors),
    legend_gp = grid::gpar(fill = condition_colors),
    title_gp = grid::gpar(fontsize = 9, fontface = "bold"),
    labels_gp = grid::gpar(fontsize = 8)
  ),
  direction = "vertical"
)
grid::pushViewport(grid::viewport(layout.pos.row = 2:3, layout.pos.col = 5))
ComplexHeatmap::draw(legends)
grid::popViewport(2)
grDevices::dev.off()

writeLines(
  capture.output(sessionInfo()),
  file.path(report_dir, "04b_combined_group_visualizations_sessionInfo.txt")
)
message("Combined PCA and ComplexHeatmap figures completed.")
