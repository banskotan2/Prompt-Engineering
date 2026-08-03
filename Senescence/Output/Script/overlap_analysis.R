# Load required libraries
library(readr)
library(ggplot2)
library(UpSetR)

# Set paths
output_table_dir <- "Output/Table/"
output_plot_dir <- "Output/Plot/"

# Find all result files available in the table directory, excluding 'full_dataset'
res_files <- list.files(output_table_dir, pattern = "_results.csv$", full.names = FALSE)
res_files <- res_files[!grepl("^full_dataset", res_files)]
comps <- gsub("_results.csv", "", res_files)

if (length(comps) == 0) {
  stop("No result files found in Output/Table/")
}

# Lists to store strictly significant genes per comparison
ups_list <- list()
downs_list <- list()

cat("Processing comparisons:\n")
for (comp in comps) {
  file_path <- paste0(output_table_dir, comp, "_results.csv")
  res <- read_csv(file_path, show_col_types = FALSE)
  
  # Strict Filter: FDR < 0.05 and non-NA padj
  sig_up <- res[!is.na(res$padj) & res$padj < 0.05 & res$log2FoldChange > 0, ]
  sig_down <- res[!is.na(res$padj) & res$padj < 0.05 & res$log2FoldChange < 0, ]
  
  ups_list[[comp]] <- unique(na.omit(sig_up$Gene_name))
  downs_list[[comp]] <- unique(na.omit(sig_down$Gene_name))
  
  cat(sprintf("%s: Up=%d, Down=%d\n", comp, length(ups_list[[comp]]), length(downs_list[[comp]])))
}

# Intersection across ALL available comparison files
common_up <- Reduce(intersect, ups_list)
common_down <- Reduce(intersect, downs_list)

cat(sprintf("\nCommonly UP across all %d groups: %d\n", length(comps), length(common_up)))
cat(sprintf("Commonly DOWN across all %d groups: %d\n", length(comps), length(common_down)))

write.csv(common_up, file = paste0(output_table_dir, "overall_intersecting_up.csv"), row.names = FALSE)
write.csv(common_down, file = paste0(output_table_dir, "overall_intersecting_down.csv"), row.names = FALSE)

# Combine common genes for the dotplot (ONLY if they are consistently one color)
all_common_genes <- c(common_up, common_down)

if (length(all_common_genes) > 0) {
  overlap_data <- data.frame()
  for (comp in comps) {
    file_path <- paste0(output_table_dir, comp, "_results.csv")
    res <- read_csv(file_path, show_col_types = FALSE)
    gene_stats <- res[res$Gene_name %in% all_common_genes, c("Gene_name", "log2FoldChange", "padj")]
    gene_stats$Comparison <- comp
    overlap_data <- rbind(overlap_data, gene_stats)
  }
  
  # Calculate average log2FoldChange for sorting
  avg_lfc <- aggregate(log2FoldChange ~ Gene_name, data = overlap_data, FUN = mean)
  
  # Reorder Gene_name as a factor based on average log2FoldChange (lowest to highest)
  # This ensures lowest avg LFC is at bottom and highest is at top of the Y axis
  overlap_data$Gene_name <- factor(overlap_data$Gene_name, 
                                   levels = avg_lfc$Gene_name[order(avg_lfc$log2FoldChange)])
  
  # Note: we don't merge avg_lfc back into overlap_data to avoid renaming columns (like log2FoldChange.1)
  
  overlap_data$minus_log10p <- -log10(overlap_data$padj)
  
  # Dot plot for common genes: Color is logFC, size is -log10(pvalue)
  overlap_plot <- ggplot(overlap_data, aes(x = Comparison, y = Gene_name, color = log2FoldChange, size = minus_log10p)) +
    geom_point() +
    scale_color_gradient2(low = "blue", mid = "white", high = "red", midpoint = 0) +
    theme_minimal() +
    ggtitle("Genes Consistently Significantly Up or Down Across All Comparisons") +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  ggsave(paste0(output_plot_dir, "comparison_overlap_dotplot.svg"), plot = overlap_plot, device = "svg", width = 10, height = max(6, length(all_common_genes)*0.3))
} else {
  cat("No genes found consistently significant across all comparisons.\n")
}

# UpSet Plots for General Structural Overview (Separated by direction)
create_upset_plot <- function(gene_list, filename, title) {
  all_set_genes <- unique(unlist(gene_list))
  num_sets <- length(gene_list)
  cat(sprintf("\n--- Debugging %s ---\n", title))
  cat(sprintf("Total genes: %d\n", length(all_set_genes)))
  cat(sprintf("Number of sets: %d\n", num_sets))
  
  upset_mat <- matrix(0, nrow = length(all_set_genes), ncol = num_sets)
  rownames(upset_mat) <- all_set_genes
  colnames(upset_mat) <- names(gene_list)
  
  for (i in seq_along(gene_list)) {
    upset_mat[all_set_genes %in% gene_list[[i]], i] <- 1
  }
  
  df_upset <- as.data.frame(upset_mat)
  cat(sprintf("DF Dimensions: %d x %d\n", nrow(df_upset), ncol(df_upset)))
  cat(sprintf("Columns: %s\n", paste(colnames(df_upset), collapse=", ")))
  
  # Write a small sample of the matrix to check if it's binary 0/1
  sample_path <- paste0(output_table_dir, "debug_", gsub(".svg", "", filename), "_sample.csv")
  write.csv(head(df_upset, 5), sample_path, row.names = TRUE)
  cat(sprintf("Sample matrix saved to: %s\n", sample_path))

  # Try forcing the print of the plot
  svg(paste0(output_plot_dir, filename), width = 14, height = 8)
  p <- upset(df_upset, nsets = num_sets, order.by = "degree")
  print(p)
  dev.off()
  cat(sprintf("Dev off called for %s\n", filename))
}

# Plot for UP genes
create_upset_plot(ups_list, "comparison_overlap_upset_up.svg", "Intersection of Upregulated Genes")

# Plot for DOWN genes
create_upset_plot(downs_list, "comparison_overlap_upset_down.svg", "Intersection of Downregulated Genes")
