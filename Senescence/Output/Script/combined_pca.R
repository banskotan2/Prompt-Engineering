# Load required libraries
library(DESeq2)
library(readr)
library(ggplot2)
library(patchwork)

# Define paths
counts_path <- "count.csv"
metadata_path <- "metadata.csv"
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

pca_plots <- list()

for (id in names(comparisons)) {
  comp_name <- comparisons[[id]]
  message("Generating PCA for ", comp_name)
  
  # Filter metadata for this comparison
  if (id == "3" || id == "4") {
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
  
  if (nrow(metadata) == 0) {
    warning("No samples found for ", comp_name)
    next
  }

  # Create DESeq2 object and VST
  metadata$Condition <- as.factor(metadata$Condition)
  dds <- DESeqDataSetFromMatrix(countData = round(as.matrix(comp_counts)), 
                                 colData = metadata, 
                                 design = ~ Condition)
  vsd <- vst(dds, blind = FALSE)
  
  # Get PCA data
  pca_data <- plotPCA(vsd, intgroup = "Condition", returnData = TRUE)
  percentVar <- round(100 * attr(pca_data, "percentVar"))
  
  # Create ggplot object
  p <- ggplot(pca_data, aes(x = PC1, y = PC2, color = Condition)) +
    geom_point(size = 2) +
    xlab(paste0("PC1: ", percentVar[1], "%")) +
    ylab(paste0("PC2: ", percentVar[2], "%")) +
    ggtitle(comp_name) +
    theme_classic() +
    theme(plot.title = element_text(hjust = 0.5, color = "black"),
          axis.text = element_text(color = "black"),
          axis.title = element_text(color = "black"))
  
  pca_plots[[id]] <- p
}

# Combine plots using patchwork
if (length(pca_plots) == 8) {
  combined_pca <- (pca_plots[["1"]] | pca_plots[["2"]] | pca_plots[["3"]] | pca_plots[["4"]]) /
                  (pca_plots[["5"]] | pca_plots[["6"]] | pca_plots[["7"]] | pca_plots[["8"]]) +
                  plot_annotation(title = "PCA Comparison Across Groups", 
                                  theme = theme(plot.title = element_text(color = "black", hjust = 0.5, size = 16)))
  
  ggsave(paste0(output_plot_dir, "combined_pca.svg"), plot = combined_pca, device = "svg", width = 16, height = 8)
  message("Combined PCA saved to Output/Plot/combined_pca.svg")
} else {
  stop("Could not generate all 8 PCA plots. Found: ", length(pca_plots))
}
