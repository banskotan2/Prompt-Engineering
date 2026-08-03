# Load required libraries
library(readxl)
library(readr)
library(ggplot2)
library(ggVennDiagram)

# Set paths
gt_path <- "Table_HAEC.xlsx"
our_results_path <- "Output/Table/HAEC_IR_results.csv"
output_plot_dir <- "Output/Plot/"

# 1. Process Ground Truth Data
gt_data <- read_excel(gt_path)
# Filter by FDR < 0.05
gt_sig <- gt_data[gt_data$FDR < 0.05, ]

# Separate into Up and Down based on logFC
gt_up <- unique(na.omit(gt_sig$seqDataFrame...1.[gt_sig$logFC > 0]))
gt_down <- unique(na.omit(gt_sig$seqDataFrame...1.[gt_sig$logFC < 0]))

# 2. Process Our Data (HAEC_IR)
our_res <- read_csv(our_results_path, show_col_types = FALSE)
# Filter by FDR < 0.05 and divide into Up/Down using Gene_stable_ID
our_up <- unique(na.omit(our_res$Gene_stable_ID[!is.na(our_res$padj) & our_res$padj < 0.05 & our_res$log2FoldChange > 0]))
our_down <- unique(na.omit(our_res$Gene_stable_ID[!is.na(our_res$padj) & our_res$padj < 0.05 & our_res$log2FoldChange < 0]))

# Create lists for Venn Diagram
up_list <- list(GroundTruth = gt_up, OurResults = our_up)
down_list <- list(GroundTruth = gt_down, OurResults = our_down)

# Discordant lists
gt_up_our_down <- list(GroundTruth_UP = gt_up, OurResults_DOWN = our_down)
gt_down_our_up <- list(GroundTruth_DOWN = gt_down, OurResults_UP = our_up)

# 3. Generate Venn Diagrams
# Up Comparison
p_up <- ggVennDiagram(up_list, label_alpha = 0) +
  scale_fill_gradient(low = "white", high = "red") +
  ggtitle("Overlap: GT-UP vs Our-UP (HAEC)") +
  theme(legend.position = "none")

# Down Comparison
p_down <- ggVennDiagram(down_list, label_alpha = 0) +
  scale_fill_gradient(low = "white", high = "blue") +
  ggtitle("Overlap: GT-DOWN vs Our-DOWN (HAEC)") +
  theme(legend.position = "none")

# Discordant Up GT / Down Our
p_disc1 <- ggVennDiagram(gt_up_our_down, label_alpha = 0) +
  scale_fill_gradient(low = "white", high = "orange") +
  ggtitle("Overlap: GT-UP vs Our-DOWN (HAEC)") +
  theme(legend.position = "none")

# Discordant Down GT / Up Our
p_disc2 <- ggVennDiagram(gt_down_our_up, label_alpha = 0) +
  scale_fill_gradient(low = "white", high = "purple") +
  ggtitle("Overlap: GT-DOWN vs Our-UP (HAEC)") +
  theme(legend.position = "none")

# Save plots
ggsave(paste0(output_plot_dir, "overlap_groundtruth_up.svg"), plot = p_up, device = "svg", width = 6, height = 5)
ggsave(paste0(output_plot_dir, "overlap_groundtruth_down.svg"), plot = p_down, device = "svg", width = 6, height = 5)
ggsave(paste0(output_plot_dir, "overlap_gtup_ourdown.svg"), plot = p_disc1, device = "svg", width = 6, height = 5)
ggsave(paste0(output_plot_dir, "overlap_gtdown_ourup.svg"), plot = p_disc2, device = "svg", width = 6, height = 5)

cat("Venn diagrams generated successfully.\n")
cat(sprintf("Consistent UP: Overlap=%d\n", length(intersect(gt_up, our_up))))
cat(sprintf("Consistent DOWN: Overlap=%d\n", length(intersect(gt_down, our_down))))
cat(sprintf("Discordant (GT-UP / Our-DOWN): Overlap=%d\n", length(intersect(gt_up, our_down))))
cat(sprintf("Discordant (GT-DOWN / Our-UP): Overlap=%d\n", length(intersect(gt_down, our_up))))
