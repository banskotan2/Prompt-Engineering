
# Load required libraries
library(ggplot2)
library(pheatmap)
library(ComplexHeatmap)
library(readr)
library(DESeq2)

# Set paths
vsd_path <- "Output/Table/full_dataset_vsd.rds"
res_path <- "Output/Table/full_dataset_res.rds"
output_plot_dir <- "Output/Plot/"

# Load data
vsd <- readRDS(vsd_path)
res_merged <- readRDS(res_path)

# 1. PCA Plot
pca_data <- plotPCA(vsd, intgroup = c("Cell", "Condition"), returnData = TRUE)
percentVar <- round(100 * attr(pca_data, "percentVar"))
pca_plot <- ggplot(pca_data, aes(x = PC1, y = PC2, color = Condition, shape = Cell)) +
  geom_point(size = 3) +
  xlab(paste0("PC1: ", percentVar[1], "% variance")) +
  ylab(paste0("PC2: ", percentVar[2], "% variance")) +
  theme_minimal() +
  ggtitle("Full Dataset PCA")

ggsave(paste0(output_plot_dir, "full_dataset_pca.svg"), plot = pca_plot, device = "svg", width = 6, height = 4)

# 2. Volcano Plot (PDF)
res_df <- res_merged
res_df$sig <- ifelse(res_df$padj < 0.05 & abs(res_df$log2FoldChange) > 1, "Significant", "Not Significant")

res_df <- res_df[!is.na(res_df$Gene_name), ]

top_up <- res_df[res_df$log2FoldChange > 0, ]
top_up <- top_up[order(top_up$padj), ][1:min(5, nrow(top_up)), ]

top_down <- res_df[res_df$log2FoldChange < 0, ]
top_down <- top_down[order(top_down$padj), ][1:min(5, nrow(top_down)), ]

label_genes <- rbind(top_up, top_down)
res_df$label <- ifelse(res_df$Gene_stable_ID %in% label_genes$Gene_stable_ID, res_df$Gene_name, "")

volcano_plot <- ggplot(res_df, aes(x = log2FoldChange, y = -log10(padj), color = sig)) +
  geom_point(alpha = 0.5) +
  geom_text(aes(label = label), vjust = 1.2, size = 3) +
  scale_color_manual(values = c("grey", "red")) +
  theme_minimal() +
  ggtitle("Full Dataset Volcano Plot")

ggsave(paste0(output_plot_dir, "full_dataset_volcano.pdf"), plot = volcano_plot, device = "pdf", width = 6, height = 4)

# 3. Heatmap (SVG)
top_genes <- res_df[order(res_df$padj), ][1:50, ]
vsd_mat <- assay(vsd)
heatmap_mat <- vsd_mat[top_genes$Gene_stable_ID, ]
heatmap_mat <- t(scale(t(heatmap_mat)))

col_anno <- data.frame(Condition = colData(vsd)$Condition, Cell = colData(vsd)$Cell)
rownames(col_anno) <- colnames(vsd)

# Correct the row names of heatmap_mat to be gene symbols
rownames(heatmap_mat) <- top_genes$Gene_name[match(rownames(heatmap_mat), top_genes$Gene_stable_ID)]

heatmap_plot <- Heatmap(heatmap_mat, 
                        name = "z-score", 
                        column_title = "Full Dataset Top 50 Genes",
                        top_annotation = HeatmapAnnotation(df = col_anno),
                        show_row_names = TRUE)

svg(paste0(output_plot_dir, "full_dataset_heatmap.svg"), width = 8, height = 10)
draw(heatmap_plot)
dev.off()
