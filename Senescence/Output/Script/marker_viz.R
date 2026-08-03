
# Load required libraries
library(readr)
library(ggplot2)

# Set paths
output_table_dir <- "Output/Table/"
output_plot_dir <- "Output/Plot/"

# Marker genes as per analysis.md
markers <- c("PTCHD4", "CDKN1A", "CDKN2A", "PURPL", "GDF15", "MKI67", "LMNB1")
# MCM family can be handled by regex search in gene names

# Comparison labels
comps <- c("HAEC_IR", "HUVEC_IR", "IMR90_IR", "IMR90_RE", "WI38_Dox", "WI38_HRAS", "WI38_IR", "WI38_Control")

# Data collection
marker_data <- data.frame()

for (comp in comps) {
  file_path <- paste0(output_table_dir, comp, "_results.csv")
  if (!file.exists(file_path)) next
  
  res <- read_csv(file_path)
  
  # Extract specific markers
  genes_found <- res[res$Gene_name %in% markers | grepl("^MCM", res$Gene_name), ]
  genes_found$Comparison <- comp
  marker_data <- rbind(marker_data, genes_found)
}

if (nrow(marker_data) > 0) {
  marker_data$minus_log10p <- -log10(marker_data$padj)
  
  # Dot plot: Color as logFC, size as -log10(pvalue)
  marker_plot <- ggplot(marker_data, aes(x = Comparison, y = Gene_name, color = log2FoldChange, size = minus_log10p)) +
    geom_point() +
    scale_color_gradient2(low = "blue", mid = "white", high = "red", midpoint = 0) +
    theme_minimal() +
    ggtitle("Marker Gene Expression across Comparisons")
  
  ggsave(paste0(output_plot_dir, "marker_genes_dotplot.svg"), plot = marker_plot, device = "svg", width = 8, height = 10)
}
