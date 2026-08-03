source("Codex/Output/Script/analysis_functions.R")
x <- load_inputs()

summary_files <- c(
  file.path(TABLE_DIR, "full_dataset_summary.csv"),
  file.path(TABLE_DIR, "all_comparison_summaries.csv")
)
if (!all(file.exists(summary_files))) stop("Full and comparison analyses must finish before final QC.")
summaries <- rbind(utils::read.csv(summary_files[1]), utils::read.csv(summary_files[2]))
utils::write.csv(summaries, file.path(TABLE_DIR, "final_analysis_summary.csv"), row.names = FALSE)

expected <- c(
  file.path(PLOT_DIR, "full_dataset_PCA.svg"),
  file.path(PLOT_DIR, "full_dataset_heatmap.svg"),
  file.path(PLOT_DIR, "full_dataset_volcano.pdf"),
  file.path(PLOT_DIR, "full_dataset_GSEA_dotplot.svg"),
  unlist(lapply(1:8, function(i) {
    p <- sprintf("comparison_%d_%s", i, GROUP_LABELS[as.character(i)])
    file.path(PLOT_DIR, paste0(p, c("_PCA.svg", "_heatmap.svg", "_volcano.pdf", "_GSEA_dotplot.svg")))
  })),
  file.path(PLOT_DIR, c(
    "overlap_up_UpSet.svg", "overlap_down_UpSet.svg",
    "overlap_all_comparisons_up_dotplot.svg", "overlap_all_comparisons_down_dotplot.svg",
    "marker_genes_dotplot.svg", "combined_group_PCA_2x4.svg",
    "combined_comparison_heatmaps_2x4.svg"
  ))
)
qc <- data.frame(file = expected, exists = file.exists(expected), bytes = ifelse(file.exists(expected), file.info(expected)$size, NA_real_))
qc$minimum_bytes <- 1000
qc$valid_size <- qc$exists & !is.na(qc$bytes) & qc$bytes >= qc$minimum_bytes
utils::write.csv(qc, file.path(TABLE_DIR, "final_output_qc.csv"), row.names = FALSE)

pkg <- utils::read.csv(file.path(TABLE_DIR, "package_status.csv"))
validation <- utils::read.csv(file.path(TABLE_DIR, "input_validation.csv"))
report <- c(
  "# Senescence RNA-seq analysis report",
  "",
  paste("Generated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Methods",
  "",
  "Raw integer gene counts were analyzed with DESeq2. Genes with counts >=10 in at least two samples were retained. The full-cohort model used `~ Cell + Condition`; each of the eight comparisons used `~ Condition`. The reported contrast is Senescent versus Control. Samples annotated `3_4` were included in both comparisons 3 and 4. Ensembl IDs were mapped through `Gene_stable_ID`, and result tables exclude rows without gene symbols. Tables are sorted by nominal p-value. GSEA used ranked Wald statistics with GO Biological Process gene sets, with NES on the plot x-axis. Differential-expression significance was defined as Benjamini-Hochberg FDR < 0.05.",
  "",
  "## Dataset",
  "",
  paste0("- Genes in count matrix: ", validation$value[validation$metric == "genes"]),
  paste0("- Samples: ", validation$value[validation$metric == "samples"]),
  paste0("- Control samples: ", validation$value[validation$metric == "control_samples"]),
  paste0("- Senescent samples: ", validation$value[validation$metric == "senescent_samples"]),
  "",
  "## Differential-expression summary",
  "",
  "| Analysis | Samples | Named tested genes | FDR < 0.05 | Up | Down |",
  "|---|---:|---:|---:|---:|---:|",
  apply(summaries, 1, function(z) paste0("| ", paste(z, collapse = " | "), " |")),
  "",
  "## Final QC",
  "",
  paste0("- Expected figures present: ", sum(qc$exists), "/", nrow(qc)),
  paste0("- Expected figures passing size validation: ", sum(qc$valid_size), "/", nrow(qc)),
  "",
  "## Software",
  "",
  paste0("- R ", getRversion()),
  paste0("- ", pkg$package[pkg$installed], " ", pkg$version[pkg$installed])
)
writeLines(report, file.path(REPORT_DIR, "Senescence_RNAseq_report.md"))
writeLines(capture.output(sessionInfo()), file.path(REPORT_DIR, "05_final_sessionInfo.txt"))
if (!all(qc$valid_size)) stop("Final QC detected missing or undersized expected output files.")
message("Final QC passed: all expected outputs exist and pass minimum-size validation.")
