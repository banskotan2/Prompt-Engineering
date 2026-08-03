options(stringsAsFactors = FALSE)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) {
  stop("Usage: Rscript 02b_gsea.R <result_prefix> <plot_title>")
}
prefix <- args[1]
title <- args[2]

suppressPackageStartupMessages({
  library(fgsea)
  library(org.Hs.eg.db)
  library(GO.db)
  library(ggplot2)
})

output_dir <- "Codex/Output"
plot_dir <- file.path(output_dir, "Plot")
table_dir <- file.path(output_dir, "Table")
report_dir <- file.path(output_dir, "Report")

safe_svg <- function(filename, width = 8, height = 6, expr) {
  grDevices::svg(filename, width = width, height = height, onefile = TRUE)
  on.exit(grDevices::dev.off(), add = TRUE)
  force(expr)
}

placeholder_svg <- function(filename, title, detail) {
  safe_svg(filename, 8, 6, {
    graphics::plot.new()
    graphics::title(main = title)
    graphics::text(0.5, 0.5, detail, cex = 1)
  })
}

input_file <- file.path(table_dir, paste0(prefix, "_DE_results.csv"))
if (!file.exists(input_file)) stop("Missing DE results: ", input_file)
tab <- utils::read.csv(input_file, check.names = FALSE)
ranks <- tab[
  is.finite(tab$stat) & !is.na(tab$Gene_name) & nzchar(tab$Gene_name),
  c("Gene_name", "stat")
]
ranks <- ranks[order(abs(ranks$stat), decreasing = TRUE), , drop = FALSE]
ranks <- ranks[!duplicated(ranks$Gene_name), , drop = FALSE]
gene_list <- ranks$stat
names(gene_list) <- ranks$Gene_name
gene_list <- sort(gene_list, decreasing = TRUE)

message(prefix, ": mapping ranked genes to GO Biological Process terms")
go_map <- suppressMessages(AnnotationDbi::select(
  org.Hs.eg.db,
  keys = names(gene_list),
  keytype = "SYMBOL",
  columns = c("GO", "ONTOLOGY")
))
go_map <- go_map[
  !is.na(go_map$GO) & go_map$ONTOLOGY == "BP" & go_map$SYMBOL %in% names(gene_list),
  c("GO", "SYMBOL")
]
pathways <- lapply(split(go_map$SYMBOL, go_map$GO), unique)
rm(go_map, ranks, tab)
invisible(gc())

message(prefix, ": running preranked fgsea")
set.seed(1)
gsea <- tryCatch(
  suppressWarnings(fgsea::fgseaMultilevel(
    pathways = pathways,
    stats = gene_list,
    minSize = 10,
    maxSize = 500,
    eps = 1e-10
  )),
  error = function(e) e
)

out_file <- file.path(table_dir, paste0(prefix, "_GSEA_GO_BP.csv"))
plot_file <- file.path(plot_dir, paste0(prefix, "_GSEA_dotplot.svg"))
if (inherits(gsea, "error")) {
  utils::write.csv(data.frame(error = conditionMessage(gsea)), out_file, row.names = FALSE)
  placeholder_svg(plot_file, paste(title, "GSEA"), conditionMessage(gsea))
  stop(conditionMessage(gsea))
}

gtab <- as.data.frame(gsea)
gtab$ID <- gtab$pathway
gtab$Description <- unname(AnnotationDbi::mapIds(
  GO.db,
  keys = gtab$ID,
  keytype = "GOID",
  column = "TERM",
  multiVals = "first"
))
gtab$p.adjust <- gtab$padj
gtab$setSize <- gtab$size
gtab <- gtab[order(is.na(gtab$p.adjust), gtab$p.adjust), , drop = FALSE]
show <- head(gtab[!is.na(gtab$p.adjust) & gtab$p.adjust < 0.05, , drop = FALSE], 20)

export <- gtab
export$leadingEdge <- vapply(export$leadingEdge, paste, collapse = ";", character(1))
utils::write.csv(export, out_file, row.names = FALSE)
if (nrow(show) == 0) {
  placeholder_svg(
    plot_file,
    paste(title, "GSEA"),
    "No GO Biological Process terms met FDR < 0.05"
  )
} else {
  show$Description <- factor(show$Description, levels = rev(show$Description))
  p <- ggplot(show, aes(NES, Description, size = setSize, color = p.adjust)) +
    geom_point() +
    scale_color_viridis_c(direction = -1, na.value = "grey60") +
    labs(
      title = paste(title, "GSEA: GO Biological Process"),
      x = "Normalized enrichment score (NES)",
      y = NULL
    ) +
    theme_bw(base_size = 10) +
    theme(plot.title = element_text(hjust = 0.5))
  ggplot2::ggsave(plot_file, p, width = 10, height = 7)
}

writeLines(
  capture.output(sessionInfo()),
  file.path(report_dir, paste0(prefix, "_GSEA_sessionInfo.txt"))
)
message(prefix, ": GSEA completed")
