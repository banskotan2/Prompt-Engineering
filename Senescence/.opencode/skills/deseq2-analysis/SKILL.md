---
name: deseq2-analysis
description: Perform reproducible bulk RNA-seq differential expression analysis using DESeq2.
---

## Responsibilities

- Validate count matrix and metadata.
- Fit the requested DESeq2 model.
- Perform differential expression testing.
- Shrink log2 fold changes.
- Generate quality-control plots.
- Export analysis-ready results.

## Workflow

1. Validate inputs.
2. Construct the requested design.
3. Run DESeq2.
4. Apply Wald tests unless instructed otherwise.
5. Shrink log2FC with apeglm when available.
6. Produce PCA and sample-distance heatmap.
7. Export transformed expression and complete result tables.

Default significance threshold:

- FDR < 0.05
