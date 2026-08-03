---
name: gsea-analysis
description: Perform functional enrichment analysis from differential expression results.
---

## Responsibilities

- Prepare ranked gene lists.
- Perform GSEA and ORA.
- Generate enrichment figures.
- Summarize enriched biological processes and pathways.

## Workflow

1. Validate input statistics.
2. Rank all genes using

   sign(log2FC) × -log10(adjusted p-value)

3. Perform GSEA and ORA.
4. Generate publication-quality enrichment plots.
5. Summarize activated and suppressed pathways.

Assume Ensembl identifiers unless instructed otherwise.
Prefer clusterProfiler and related Bioconductor packages.
