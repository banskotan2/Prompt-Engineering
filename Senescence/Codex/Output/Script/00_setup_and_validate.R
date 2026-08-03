options(stringsAsFactors = FALSE)

output_dir <- "Codex/Output"
dirs <- file.path(output_dir, c("Plot", "Table", "Script", "Report"))
invisible(lapply(dirs, dir.create, recursive = TRUE, showWarnings = FALSE))

required_files <- c(
  "count.csv",
  "metadata.csv",
  "Homo_sapiens_HG38_GRCH38_104_Annotation.txt"
)
if (!all(file.exists(required_files))) {
  stop("Missing required input(s): ", paste(required_files[!file.exists(required_files)], collapse = ", "))
}

packages <- c(
  "DESeq2", "ggplot2", "pheatmap", "ggrepel", "clusterProfiler",
  "org.Hs.eg.db", "GO.db", "AnnotationDbi", "fgsea", "enrichplot", "UpSetR", "patchwork", "ComplexHeatmap", "circlize", "svglite", "RColorBrewer"
)
package_status <- data.frame(
  package = packages,
  installed = vapply(packages, requireNamespace, logical(1), quietly = TRUE),
  version = vapply(packages, function(x) {
    if (requireNamespace(x, quietly = TRUE)) as.character(utils::packageVersion(x)) else NA_character_
  }, character(1))
)
utils::write.csv(package_status, file.path(output_dir, "Table", "package_status.csv"), row.names = FALSE)

if (!package_status$installed[package_status$package == "DESeq2"]) {
  stop("DESeq2 is not installed. Package installation is prohibited, so analysis cannot continue.")
}
if (!package_status$installed[package_status$package == "ggplot2"]) {
  stop("ggplot2 is not installed. Package installation is prohibited, so analysis cannot continue.")
}

counts <- utils::read.csv("count.csv", row.names = 1, check.names = FALSE)
metadata <- utils::read.csv("metadata.csv", check.names = FALSE, fileEncoding = "UTF-8-BOM")
annotation <- utils::read.delim(
  "Homo_sapiens_HG38_GRCH38_104_Annotation.txt",
  check.names = FALSE,
  quote = "",
  comment.char = ""
)

required_metadata <- c("Filename", "Cell", "Condition", "Comparison")
if (!all(required_metadata %in% names(metadata))) {
  stop("Metadata lacks required column(s): ", paste(setdiff(required_metadata, names(metadata)), collapse = ", "))
}
if (!all(c("Gene_stable_ID", "Gene_name") %in% names(annotation))) {
  stop("Annotation must contain Gene_stable_ID and Gene_name.")
}
if (anyDuplicated(rownames(counts))) stop("count.csv contains duplicated gene IDs.")
if (anyDuplicated(metadata$Filename)) stop("metadata.csv contains duplicated Filename values.")
if (!setequal(colnames(counts), metadata$Filename)) {
  stop("The count matrix columns and metadata Filename values do not match.")
}
if (!all(metadata$Condition %in% c("Control", "Senescent"))) {
  stop("Condition values must be Control or Senescent.")
}
if (any(!is.finite(as.matrix(counts))) || any(as.matrix(counts) < 0)) {
  stop("Counts must be finite and non-negative.")
}
if (any(abs(as.matrix(counts) - round(as.matrix(counts))) > .Machine$double.eps^0.5)) {
  stop("DESeq2 requires integer counts.")
}

validation <- data.frame(
  metric = c(
    "genes", "samples", "annotation_rows", "mapped_gene_ids", "named_gene_ids",
    "control_samples", "senescent_samples"
  ),
  value = c(
    nrow(counts), ncol(counts), nrow(annotation),
    sum(rownames(counts) %in% annotation$Gene_stable_ID),
    sum(rownames(counts) %in% annotation$Gene_stable_ID[!is.na(annotation$Gene_name) & annotation$Gene_name != ""]),
    sum(metadata$Condition == "Control"), sum(metadata$Condition == "Senescent")
  )
)
utils::write.csv(validation, file.path(output_dir, "Table", "input_validation.csv"), row.names = FALSE)

comparison_membership <- do.call(rbind, lapply(1:8, function(i) {
  selected <- metadata$Comparison == as.character(i) |
    (i %in% c(3, 4) & metadata$Comparison == "3_4")
  data.frame(
    comparison = i,
    samples = sum(selected),
    controls = sum(selected & metadata$Condition == "Control"),
    senescent = sum(selected & metadata$Condition == "Senescent")
  )
}))
utils::write.csv(
  comparison_membership,
  file.path(output_dir, "Table", "comparison_sample_counts.csv"),
  row.names = FALSE
)
if (any(comparison_membership$controls == 0 | comparison_membership$senescent == 0)) {
  stop("At least one comparison lacks Control or Senescent samples.")
}

writeLines(capture.output(sessionInfo()), file.path(output_dir, "Report", "setup_sessionInfo.txt"))
message("Input validation completed successfully.")
