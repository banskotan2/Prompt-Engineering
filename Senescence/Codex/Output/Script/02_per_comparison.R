source("Codex/Output/Script/analysis_functions.R")
x <- load_inputs()
summaries <- vector("list", 8)
for (i in 1:8) {
  selected <- comparison_samples(x$metadata, i)
  md <- droplevels(x$metadata[selected, , drop = FALSE])
  ct <- x$counts[, rownames(md), drop = FALSE]
  prefix <- sprintf("comparison_%d_%s", i, GROUP_LABELS[as.character(i)])
  message("Running ", prefix)
  summaries[[i]] <- run_deseq_analysis(
    ct, md, x$annotation, ~ Condition,
    prefix = prefix, title = paste0("Comparison ", i, ": ", GROUP_LABELS[as.character(i)])
  )
  invisible(gc())
}
utils::write.csv(do.call(rbind, summaries), file.path(TABLE_DIR, "all_comparison_summaries.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(REPORT_DIR, "02_per_comparison_sessionInfo.txt"))
