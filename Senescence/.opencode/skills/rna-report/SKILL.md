---

name: rna-report
description: Generate manuscript-style reports from completed bulk RNA-seq analyses, including differential expression, visualization, and functional enrichment results.
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Purpose

This skill writes publication-quality reports from completed RNA-seq analyses. It synthesizes outputs from DESeq2, visualization, and enrichment analyses into a coherent scientific narrative suitable for manuscripts, technical reports, or supplementary materials.

This skill does **not** perform statistical analyses. It interprets existing results and presents them clearly and accurately.

## Responsibilities

* Read outputs from DESeq2 analyses.
* Incorporate visualization results.
* Summarize GSEA and pathway enrichment analyses.
* Produce manuscript-style sections.
* Maintain a scientific, objective writing style.
* Clearly distinguish observations from interpretation.

## Default assumptions

The following analyses have already been completed:

* Differential expression analysis
* Quality control
* Visualization
* Functional enrichment (if available)

Do not rerun analyses unless explicitly requested.

Do not invent biological interpretations that are unsupported by the data.

Avoid overstating statistical significance or causality.

## Report structure

Generate the report using the following sections.

### Title

Provide a concise descriptive title based on the biological comparison.

### Abstract

Summarize:

* study objective
* experimental design
* major findings
* principal biological conclusions

### Introduction

Briefly describe:

* biological background
* motivation
* experimental question
* hypothesis (if appropriate)

### Methods

Summarize the computational workflow, including:

* preprocessing
* DESeq2 version
* experimental design formula
* normalization
* differential expression testing
* log2 fold-change shrinkage
* multiple testing correction
* visualization tools
* enrichment analysis tools
* software versions when available

Methods should be reproducible without becoming an execution log.

### Results

Organize logically.

Include:

* quality-control observations
* PCA and clustering results
* differential expression summary
* top differentially expressed genes
* volcano and heatmap summaries
* pathway enrichment results
* GSEA findings
* key biological themes

Reference figures and tables naturally.

### Discussion

Interpret the findings.

Discuss:

* biological significance
* agreement with existing knowledge when appropriate
* unexpected observations
* limitations
* potential confounding factors
* future directions

Clearly separate interpretation from statistical evidence.

### Conclusion

Provide a concise summary of the major findings and their implications.

Avoid introducing new results.

### Figure legends

Generate concise publication-style legends for every figure.

### Tables

Include summaries such as:

* sample information
* differential expression statistics
* top differentially expressed genes
* enriched pathways

## Writing style

Write in a scientific style suitable for journals such as:

* Nature Communications
* Genome Biology
* Nucleic Acids Research
* PLOS Biology

Use:

* precise language
* objective tone
* active voice when appropriate
* clear transitions between sections

Avoid:

* unsupported speculation
* exaggerated claims
* repetitive descriptions
* unnecessary jargon

## Quality checks

Before finishing, verify that:

* every major result is supported by data
* statistical thresholds are reported correctly
* figures are referenced consistently
* gene names are formatted consistently
* pathway names match the enrichment results
* conclusions do not exceed the evidence presented

