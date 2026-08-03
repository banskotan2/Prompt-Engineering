# Load required libraries
library(DESeq2)
library(readr)
library(ggplot2)
library(ComplexHeatmap)
library(grid)
library(cowplot)

# Define paths
counts_path <- "count.csv"
metadata_path <- "metadata.csv"
results_dir <- "Output/Table/"
output_plot_dir <- "Output/Plot/"

# Load data
counts_raw <- read_csv(counts_path, skip = 0)
counts <- as.data.frame(counts_raw)
rownames(counts) <- counts[,1]
counts <- counts[,-1]
metadata_full <- read_csv(metadata_path)
metadata_full$Comparison <- trimws(as.character(metadata_full$Comparison))

# Comparison mapping
comparisons <- list(
  "1" = "HAEC_IR",
  "2" = "HUVEC_IR",
  "3" = "IMR90_IR",
  "4" = "IMR90_RE",
  "5" = "WI38_Dox",
  "6" = "WI38_HRAS",
  "7" = "WI38_IR",
  "8" = "WI38_RE"
)

heatmap_grobs <- list()

for (id in names(comparisons)) {
  comp_name <- comparisons[[id]]
  message("Generating Heatmap for ", comp_name)
  
  # Filter metadata for this comparison
  if (id == "3" || id == "4") {
    idx <- which(metadata_full$Comparison == id | metadata_full$Comparison == "3_4")
    metadata <- metadata_full[idx, ]
  } else {
    idx <- which(metadata_full$Comparison == id)
    metadata <- metadata_full[idx, ]
  }
  
  # Order metadata: Control first, then Senescent
  metadata$Condition <- factor(metadata$Condition, levels = c("Control", "Senescent"))
  metadata <- metadata[order(metadata$Condition), ]
  
  # Keep only common samples in the new order
  comp_counts <- counts[, metadata$Filename]
  
  if (nrow(metadata) == 0) {
    warning("No samples found for ", comp_name)
    next
  }

  # Create DESeq2 object and VST
  dds <- DESeqDataSetFromMatrix(countData = round(as.matrix(comp_counts)), 
                                 colData = metadata, 
                                 design = ~ Condition)
  vsd <- vst(dds, blind = FALSE)
  
  # ... (the rest of gene selection remains same as current file) ...
  
  # Get top 50 genes from the results file to ensure consistency with per_comparison script
  res_file <- paste0(results_dir, comp_name, "_results.csv")
  if (!file.exists(res_file)) {
    warning("Results file missing for ", comp_name)
    next
  }
  res_merged <- read_csv(res_file, show_col_types = FALSE)
  res_fixed <- res_merged[!is.na(res_merged$Gene_name), ]
  
  # Get top 25 Up and top 25 Down genes based on padj
  up_genes <- res_fixed[res_fixed$log2FoldChange > 0, ]
  up_genes <- up_genes[order(up_genes$padj), ][1:min(25, nrow(up_genes)), ]
  
  down_genes <- res_fixed[res_fixed$log2FoldChange < 0, ]
  down_genes <- down_genes[order(down_genes$padj), ][1:min(25, nrow(down_genes)), ]
  
  top_genes_df <- rbind(up_genes, down_genes)
  
  # Extract and scale matrix
  heatmap_mat <- assay(vsd)[top_genes_df$Gene_stable_ID, ]
  heatmap_mat <- t(scale(t(heatmap_mat)))
  rownames(heatmap_mat) <- top_genes_df$Gene_name[match(rownames(heatmap_mat), top_genes_df$Gene_stable_ID)]
  
  col_anno <- data.frame(Condition = metadata$Condition)
  rownames(col_anno) <- metadata$Filename
  
  # Create heatmap object
  ht <- Heatmap(heatmap_mat, 
                name = "z-score", 
                column_title = comp_name,
                top_annotation = HeatmapAnnotation(df = col_anno),
                show_row_names = TRUE,
                cluster_columns = FALSE)
  
  # To capture a ComplexHeatmap as a grob reliably in non-interactive mode:
  grid.newpage()
  draw(ht)
  heatmap_grobs[[id]] <- grid.grab()
}

# Combine grobs into 2x4 grid using cowplot
if (length(heatmap_grobs) == 8) {
  combined_heatmap <- plot_grid(
    plotlist = heatmap_grobs,
    ncol = 4,
    nrow = 2
  )
  
  ggsave(paste0(output_plot_dir, "combined_heatmaps.svg"), plot = combined_heatmap, device = "svg", width = 24, height = 20)
  message("Combined Heatmaps saved to Output/Plot/combined_heatmaps.svg")
} else {
  stop("Could not generate all 8 heatmaps. Found: ", length(heatmap_grobs))
}
