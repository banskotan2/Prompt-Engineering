# Senescence RNA-seq Project

Perform a full analysis. Generate figures in SVG format except for volcano plots. Volcano should be in PDF format.

## Environment

- Use R only.
- Run `module load R` before analysis.
- Write each analysis step as a separate R script.

## Inputs

- `count.csv`
- `metadata.csv`
- `Homo_sapiens_HG38_GRCH38_104_Annotation.txt`
  - use `Gene_stable_ID` for ENSG mapping

## Output structure

Create only:

Output/
├── Plot/
├── Table/
├── Script/
└── Report/

Store figures, tables, scripts, and reports in their corresponding directories. 
**Important** For each comparison, we need PCA, heatmaps and volcano plots. Sort by pvalue. Remove genes with no gene-names. Label top 5 genes per upregulated and downregulated.

## Metadata

- `Filename` matches `count.csv` column names.
- `Cell` = cell type.
- `Condition` = Control or Senescent.
- `Comparison` = groups 1–8.
- Samples labeled `3_4` belong to both groups 3 and 4.

Group labels:

1. HAEC_IR
2. HUVEC_IR
3. IMR90_IR
4. IMR90_RE
5. WI38_Dox
6. WI38_HRAS
7. WI38_IR
8. WI38_RE

## Workflow

Run analyses in this order:

1. Full dataset
2. Per-comparison analyses
3. Gene overlap analysis
4. Marker gene visualization
5. Final QC

Use:

- `deseq2-analysis`
- `rna-visualization`
- `gsea-analysis`
- `rna-qc`
- `rna-report`

Coordinate the workflow with `omics-orchestrator`.

## Full dataset

Run DE analysis with

```r
design = ~ Cell + Condition
```

followed by visualization and enrichment.

## Comparison analyses

For each Comparison (1–8):

- include matching samples
- include `3_4` samples in groups 3 and 4
- require both Control and Senescent samples
- use

```r
design = ~ Condition
```

Run differential expression, visualization, and enrichment.

## Overlap analysis

Generate a separate script that

- uses gene symbols
- selects genes with FDR < 0.05
- separates positive and negative log2FC
- exports an SVG UpSet plot
- keeps only genes that are found across all comparisons.
	- reports the overlapping genes. Visualize using a dot plot. Fill is logFC, and size is -log10(pvalue)


## Marker genes

Generate a dot plot for

- PTCHD4
- MCM family
- CDKN1A
- CDKN2A
- PURPL
- GDF15
- MKI67
- LMNB1

The dotplot will have fill as logFC and size is -log10(pvalue)

