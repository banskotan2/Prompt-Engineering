---
name: rna-visualization
description: Generate publication-quality figures from RNA-seq analysis.
---

## Responsibilities

Create reproducible visualizations from DESeq2 outputs.

Supported figures include

- PCA
- sample distance heatmap
- volcano plot
- MA plot
- heatmap
- gene expression plots
- clustering

## Guidelines

- Use ComplexHeatmap for heatmaps. Always include legends such as Condition.
- Use ggplot2 unless a specialized package is preferred.
- Export SVG figures unless otherwise requested.
- Export volcano plots as PDF.
- Keep figure generation separate from statistical analysis.
