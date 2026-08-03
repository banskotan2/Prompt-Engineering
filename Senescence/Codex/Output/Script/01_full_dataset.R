source("Codex/Output/Script/analysis_functions.R")
x <- load_inputs()
run_deseq_analysis(
  x$counts, x$metadata, x$annotation, ~ Cell + Condition,
  prefix = "full_dataset", title = "Full dataset"
)
writeLines(capture.output(sessionInfo()), file.path(REPORT_DIR, "01_full_dataset_sessionInfo.txt"))
