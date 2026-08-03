
# Load required libraries
library(DESeq2)
library(readr)
library(ggplot2)
library(ComplexHeatmap)
library(ggrepel)

# Define paths
counts_path <- "count.csv"
metadata_path <- "metadata.csv"
anno_path <- "Homo_sapiens_HG38_GRCH38_104_Annotation.txt"
output_table_dir <- "Output/Table/"
output_plot_dir <- "Output/Plot/"

# Load data
counts_raw <- read_csv(counts_path, skip = 0)
counts <- as.data.frame(counts_raw)
rownames(counts) <- counts[,1]
counts <- counts[,-1]

metadata_full <- read_csv(metadata_path)
metadata_full$Comparison <- trimws(as.character(metadata_full$Comparison))
anno <- read.delim(anno_path, header = TRUE, sep = "\t")

# --- Global Match Check (Once at start) ---
count_cols <- colnames(counts)
meta_files <- metadata_full$Filename

missing_in_counts <- setdiff(meta_files, count_cols)
missing_in_meta <- setdiff(count_cols, meta_files)

if (length(missing_in_counts) > 0) {
  warning("Global Alert: Samples in metadata but missing from counts: ", paste(missing_in_counts, collapse = ", "))
}
if (length(missing_in_meta) > 0) {
  warning("Global Alert: Samples in counts but missing from metadata: ", paste(missing_in_meta, collapse = ", "))
}

# Ensure shared samples are consistent across all subsets later
common_samples_global <- intersect(meta_files, count_cols)
# -------------------------------------------------------

# Comparison mapping

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

for (id in names(comparisons)) {
  comp_name <- comparisons[[id]]
  message("Processing Comparison ", id, ": ", comp_name)
  
  # Filter metadata for this comparison
    if (id == "3" || id == "4") {
      # Include samples for this comparison OR shared controls labeled '3_4'
      idx <- which(metadata_full$Comparison == id | metadata_full$Comparison == "3_4")
      metadata <- metadata_full[idx, ]
    } else {
      idx <- which(metadata_full$Comparison == id)
      metadata <- metadata_full[idx, ]
    }
  
  # Keep only common samples
  common_samples <- intersect(metadata$Filename, colnames(counts))
  metadata <- metadata[metadata$Filename %in% common_samples, ]
  comp_counts <- counts[, metadata$Filename]

  if (nrow(metadata) != ncol(comp_counts)) {
    stop("Fatal Error: Metadata and Counts mismatch in comparison ", comp_name)
  }
  
  if (nrow(metadata) == 0) {
    message("No samples found for ", comp_name)
    next
  }

  # Check for both Control and Senescent
  if (length(unique(metadata$Condition)) < 2) {
    message("Skipping ", comp_name, ": Missing one of the conditions.")
    next
  }

  # Create DESeq2 object
  metadata$Condition <- as.factor(metadata$Condition)
  dds <- DESeqDataSetFromMatrix(countData = round(as.matrix(comp_counts)), 
                                colData = metadata, 
                                design = ~ Condition)
  
  dds <- DESeq(dds)
  res <- results(dds, contrast=c("Condition", "Senescent", "Control"))
  
  # Merge with annotation
  res_df <- as.data.frame(res)
  res_df$Gene_stable_ID <- rownames(res_df)
  res_merged <- merge(res_df, anno[, c("Gene_stable_ID", "Gene_name")], by = "Gene_stable_ID")
  
  # Save table
  write.csv(res_merged, file = paste0(output_table_dir, comp_name, "_results.csv"), row.names = FALSE)
  
  # Visualizations
  vsd <- vst(dds, blind = FALSE)
  
  # PCA
  pca_data <- plotPCA(vsd, intgroup = "Condition", returnData = TRUE)
  percentVar <- round(100 * attr(pca_data, "percentVar"))
  pca_plot <- ggplot(pca_data, aes(x = PC1, y = PC2, color = Condition)) +
    geom_point(size = 3) +
    xlab(paste0("PC1: ", percentVar[1], "% variance")) +
    ylab(paste0("PC2: ", percentVar[2], "% variance")) +
    theme_minimal() +
    ggtitle(paste0("PCA - ", comp_name))
  ggsave(paste0(output_plot_dir, comp_name, "_pca.svg"), plot = pca_plot, device = "svg", width = 6, height = 4)
  
  # Volcano
  res_df_fixed <- res_merged[!is.na(res_merged$Gene_name), ]
  
  # 1. Color based on LogFC direction and significance
  res_df_fixed$color_cat <- "Not Significant"
  res_df_fixed$color_cat[res_df_fixed$padj < 0.05 & res_df_fixed$log2FoldChange > 1] <- "Up"
  res_df_fixed$color_cat[res_df_fixed$padj < 0.05 & res_df_fixed$log2FoldChange < -1] <- "Down"
  
  # 2. Identify Top 5 Up and Down for labels using ggrepel
  top_up <- res_df_fixed[res_df_fixed$log2FoldChange > 0, ]
  top_up <- top_up[order(top_up$padj), ][1:min(5, nrow(top_up)), ]
  
  top_down <- res_df_fixed[res_df_fixed$log2FoldChange < 0, ]
  top_down <- top_down[order(top_down$padj), ][1:min(5, nrow(top_down)), ]
  
  label_genes <- rbind(top_up, top_down)
  res_df_fixed$label <- ifelse(res_df_fixed$Gene_stable_ID %in% label_genes$Gene_stable_ID, res_df_fixed$Gene_name, "")
  
  volcano_plot <- ggplot(res_df_fixed, aes(x = log2FoldChange, y = -log10(padj), color = color_cat)) +
    geom_point(alpha = 0.5) +
    geom_text_repel(aes(label = label), max.overlaps = Inf, size = 3) +
    scale_color_manual(values = c("Down" = "blue", "Up" = "red", "Not Significant" = "grey")) +
    theme_minimal() +
    ggtitle(paste0("Volcano - ", comp_name)) +
    xlab("log2 Fold Change") +
    ylab("-log10 Adjusted P-value")
  ggsave(paste0(output_plot_dir, comp_name, "_volcano.pdf"), plot = volcano_plot, device = "pdf", width = 6, height = 4)

  # Heatmap
  top_genes <- res_df_fixed[order(res_df_fixed$padj), ][1:50, ]
  heatmap_mat <- assay(vsd)[top_genes$Gene_stable_ID, ]
  heatmap_mat <- t(scale(t(heatmap_mat)))
  rownames(heatmap_mat) <- top_genes$Gene_name[match(rownames(heatmap_mat), top_genes$Gene_stable_ID)]
  
  col_anno <- data.frame(Condition = colData(vsd)$Condition)
  rownames(col_anno) <- colnames(vsd)
  
  heatmap_plot <- Heatmap(heatmap_mat, 
                          name = "z-score", 
                          # Corrected column title to avoid issues with ComplexHeatmap if needed
                          column_title = paste0("Top 50 Genes - ", comp_name),
                          top_annotation = HeatmapAnnotation(df = col_anno),
                          show_row_names = TRUE)
  svg(paste0(output_plot_dir, comp_name, "_heatmap.svg"), width = 8, height = 10)
  draw(heatmap_plot)
  dev.off()
}
