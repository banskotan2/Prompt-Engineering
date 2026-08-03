# Senescence RNA-seq analysis report

Generated: 2026-07-16 19:59:15 EDT

## Methods

Raw integer gene counts were analyzed with DESeq2. Genes with counts >=10 in at least two samples were retained. The full-cohort model used `~ Cell + Condition`; each of the eight comparisons used `~ Condition`. The reported contrast is Senescent versus Control. Samples annotated `3_4` were included in both comparisons 3 and 4. Ensembl IDs were mapped through `Gene_stable_ID`, and result tables exclude rows without gene symbols. Tables are sorted by nominal p-value. GSEA used ranked Wald statistics with GO Biological Process gene sets, with NES on the plot x-axis. Differential-expression significance was defined as Benjamini-Hochberg FDR < 0.05.

## Dataset

- Genes in count matrix: 60605
- Samples: 37
- Control samples: 17
- Senescent samples: 20

## Differential-expression summary

| Analysis | Samples | Named tested genes | FDR < 0.05 | Up | Down |
|---|---:|---:|---:|---:|---:|
| full_dataset | 37 | 24914 |  3220 | 1895 | 1325 |
| comparison_1_HAEC_IR |  5 | 18708 |  7945 | 3650 | 4295 |
| comparison_2_HUVEC_IR |  6 | 19184 |  8145 | 3616 | 4529 |
| comparison_3_IMR90_IR |  4 | 19049 | 10222 | 5899 | 4323 |
| comparison_4_IMR90_RE |  4 | 18845 |  9567 | 5526 | 4041 |
| comparison_5_WI38_Dox |  8 | 21303 |  1392 |  819 |  573 |
| comparison_6_WI38_HRAS |  4 | 18316 |  8105 | 4837 | 3268 |
| comparison_7_WI38_IR |  4 | 19841 |  4606 | 2447 | 2159 |
| comparison_8_WI38_RE |  4 | 19252 |  5431 | 2607 | 2824 |

## Final QC

- Expected figures present: 43/43
- Expected figures passing size validation: 43/43

## Software

- R 4.5.2
- DESeq2 1.50.2
- ggplot2 4.0.3
- pheatmap 1.0.13
- ggrepel 0.9.8
- clusterProfiler 4.18.4
- org.Hs.eg.db 3.22.0
- GO.db 3.22.0
- AnnotationDbi 1.72.0
- fgsea 1.36.2
- enrichplot 1.30.4
- UpSetR 1.4.0
- patchwork 1.3.2
- ComplexHeatmap 2.26.1
- circlize 0.4.17
- svglite 2.2.2
- RColorBrewer 1.1.3
