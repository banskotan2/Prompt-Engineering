
# Load required libraries
library(DESeq2)
library(readr)

# Define paths
counts_path <- "count.csv"
metadata_path <- "metadata.csv"
anno_path <- "Homo_sapiens_HG38_GRCH38_104_Annotation.txt"
output_table_dir <- "Output/Table/"

# Load data
counts <- read_csv(counts_path, skip = 0)
counts <- as.data.frame(counts)
rownames(counts) <- counts[,1]
counts <- counts[,-1]

metadata <- read_csv(metadata_path)

# --- Explicit Match Check ---
count_cols <- colnames(counts)
meta_files <- metadata$Filename

missing_in_counts <- setdiff(meta_files, count_cols)
missing_in_meta <- setdiff(count_cols, meta_files)

if (length(missing_in_counts) > 0) {
  warning("Samples in metadata but missing from counts: ", paste(missing_in_counts, collapse = ", "))
}
if (length(missing_in_meta) > 0) {
  warning("Samples in counts but missing from metadata: ", paste(missing_in_meta, collapse = ", "))
}

# Ensure filename matches column names of counts and are in the same order
common_samples <- intersect(meta_files, count_cols)
metadata <- metadata[metadata$Filename %in% common_samples, ]
counts <- counts[, metadata$Filename]

if (nrow(metadata) != ncol(counts)) {
  stop("Fatal Error: Metadata rows and Count columns do not match after alignment.")
}
cat("Success: Metadata and Counts aligned. Total samples: ", nrow(metadata), "\n")
# ----------------------------

# Convert to factors

# Convert to factors
metadata$Cell <- as.factor(metadata$Cell)
metadata$Condition <- as.factor(metadata$Condition)

# Create DESeq2 object
dds <- DESeqDataSetFromMatrix(countData = round(as.matrix(counts)), 
                              colData = metadata, 
                              design = ~ Cell + Condition)

# Run DESeq2
dds <- DESeq(dds)

# Get results for Condition (Senescent vs Control)
res <- results(dds, contrast=c("Condition", "Senescent", "Control"))

# Load annotation to add gene names
anno <- read.delim(anno_path, header = TRUE, sep = "\t")
res_df <- as.data.frame(res)
res_df$Gene_stable_ID <- rownames(res_df)
res_merged <- merge(res_df, anno[, c("Gene_stable_ID", "Gene_name")], by = "Gene_stable_ID")

# Save results
write.csv(res_merged, file = paste0(output_table_dir, "full_dataset_results.csv"), row.names = FALSE)

# Export normalized counts for visualization
vsd <- vst(dds, blind = FALSE)
write.csv(assay(vsd), file = paste0(output_table_dir, "full_dataset_normalized_counts.csv"))
saveRDS(vsd, file = paste0(output_table_dir, "full_dataset_vsd.rds"))
saveRDS(res_merged, file = paste0(output_table_dir, "full_dataset_res.rds"))
