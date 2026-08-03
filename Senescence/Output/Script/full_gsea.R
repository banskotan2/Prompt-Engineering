
# Load required libraries
library(clusterProfiler)
library(org.Hs.eg.db)
library(readr)
library(ggplot2)

# Set paths
res_path <- "Output/Table/full_dataset_res.rds"
output_table_dir <- "Output/Table/"
output_plot_dir <- "Output/Plot/"

# Load data
res_merged <- readRDS(res_path)
res_df <- as.data.frame(res_merged)

# Rank calculation: sign(log2FC) * -log10(padj)
res_df <- res_df[!is.na(res_df$padj) & !is.na(res_df$log2FoldChange), ]
res_df$rank <- sign(res_df$log2FoldChange) * -log10(res_df$padj)

# Create ranked list sorted descending
ranked_list <- res_df$rank[order(res_df$rank, decreasing = TRUE)]
names(ranked_list) <- res_df$Gene_stable_ID[order(res_df$rank, decreasing = TRUE)]

# GO Enrichment (BP) - removing minSize to use default and avoid conflict
ego <- gseGO(geneList = ranked_list, 
             OrgDb = org.Hs.eg.db, 
             keyType = "ENSEMBL", 
             ont = "BP", 
             pvalueCutoff = 0.05)

# Save and Plot
write.csv(as.data.frame(ego), file = paste0(output_table_dir, "full_dataset_gsea_go.csv"))

dotplot(ego, showCategory = 20) -> gsea_plot
ggsave(paste0(output_plot_dir, "full_dataset_gsea_go.svg"), plot = gsea_plot, device = "svg", width = 8, height = 6)
