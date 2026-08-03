# Transcriptomic Profiling of Cellular Senescence Across Diverse Human Primary Cell Types and Induction Models

## Abstract
Cellular senescence is a state of permanent cell cycle arrest characterized by distinct molecular changes; however, the extent to which these changes are conserved across different cell types and induction triggers remains partially understood. In this study, we performed bulk RNA-seq analysis on a diverse set of human primary cells—including endothelial cells (HAEC, HUVEC) and fibroblasts (IMR90, WI38)—subjected to various senescence-inducing stimuli: ionizing radiation (IR), replicative exhaustion (RE), oncogene activation (HRAS), and chemical induction (Dox). Our results demonstrate a significant transcriptomic shift across all models. We identified a core "senescence signature" consisting of 7 universally upregulated genes (including *PTCHD4*) and 14 universally downregulated genes. Gene Set Enrichment Analysis (GSEA) revealed a consistent and profound downregulation of pathways related to DNA replication, mitotic sister chromatid segregation, and the cell cycle. These findings suggest that while induction-specific responses exist, cellular senescence converges on a conserved molecular program defined by the collapse of proliferative machinery.

## Introduction
Cellular senescence serves as a critical biological mechanism for preventing the proliferation of damaged or malignant cells. This state is marked by an irreversible arrest in the $G_1$ phase of the cell cycle and the secretion of a complex array of pro-inflammatory factors known as the senescence-associated secretory phenotype (SASP). While various stressors—such as telomere attrition, oxidative stress, and oncogene activation—can trigger senescence, it is unclear whether these disparate triggers converge on a universal transcriptomic state or produce model-specific profiles.

The objective of this study was to characterize the commonalities and differences in the transcriptomes of senescent cells across multiple human primary cell lines and induction methods. We hypothesized that despite the variety of inputs (IR, RE, HRAS, Dox) and cell types (endothelial vs. fibroblast), a core senescence-associated gene expression program is maintained, primarily characterized by the suppression of proliferation-related pathways.

## Methods
### Computational Workflow
RNA-seq data from multiple human primary cell lines were analyzed to compare Control versus Senescent states. 

**Differential Expression Analysis:**
Differential expression (DE) was performed using DESeq2 in R. For the aggregate analysis across all samples, a generalized linear model with the design formula `~ Cell + Condition` was utilized to account for cell-type variability while isolating the effect of senescence. For individual comparison groups (e.g., HAEC_IR, WI38_HRAS), the design formula `~ Condition` was used. Data were normalized using the median-of-ratios method. Statistical significance was determined using a Wald test followed by Benjamini-Hochberg multiple testing correction to obtain adjusted p-values ($\text{padj}$).

**Functional Enrichment:**
Gene Set Enrichment Analysis (GSEA) was conducted on the full dataset using Gene Ontology (GO) term sets. Genes were ranked based on their $\text{log}_2\text{fold-change}$ and statistical significance. The Normalized Enrichment Score (NES) was used to quantify the degree of pathway overrepresentation.

**Visualization:**
Principal Component Analysis (PCA) was performed on variance-stabilizing transformed (VST) data to assess clustering and quality. Volcano plots, heatmaps, and UpSet plots were generated to visualize DE genes and intersections between different senescence models.

## Results
### Global Transcriptomic Variance and Quality Control
PCA analysis of the full dataset reveals a clear separation of samples based on both cell type and condition. While cell-type-specific variance is prominent, there is a consistent shift in the expression profile moving from Control to Senescent states across all tested models (Fig: `combined_pca.svg`).

### Differential Expression Analysis
The aggregate analysis identified a wide array of differentially expressed genes. In the full dataset, we observed significant changes in gene expression associated with cellular arrest and stress response. 

Individual comparison analyses for HAEC_IR, HUVEC_IR, IMR90_IR/RE, and WI38_Dox/HRAS/IR/RE showed high consistency in the direction of change for key marker genes. Volcano plots for each comparison highlight a substantial number of upregulated and downregulated transcripts ($\text{padj} < 0.05$), reflecting a robust senescence response across all triggers (Fig: `*_volcano.pdf`).

### Identification of a Core Senescence Signature
To identify a universal transcriptomic signature, we performed an overlap analysis of the DE genes across all eight comparison groups. We identified:
- **Commonly Upregulated Genes (7):** *CCND3, ARRDC4, PAM, GPR155, TNFRSF10C,* and *PTCHD4*.
- **Commonly Downregulated Genes (14):** *CDKN2C, H1-3, H1-1, NIBAN1, PARP1, CDCA7L, H1-4, SLFN11, CBX2, H2AC20, PTMA, ITPRIPL1,* and *H3C11*.

Specifically, the universal upregulation of *PTCHD4* aligns with its known role as a reliable marker of cellular senescence. The intersection analysis confirms that while much of the response is model-specific, a lean but consistent lajak of genes defines the transition to senescence (Fig: `comparison_overlap_upset_up.svg`, `comparison_overlap_upsset_down.svg`).

### Functional Enrichment Analysis
GSEA results for the full dataset indicate a massive and coordinated downregulation of the cell cycle machinery. The most significantly downregulated pathways ($\text{NES} < -2.5, \text{p-adj} < 0.01$) include:
- **Mitotic Processes:** Sister chromatid segregation (NES $\approx -2.73$), mitotic nuclear division, and chromosome separation.
- **DNA Metabolism:** DNA replication and double-strand break repair via homologous recombination.
- **Nuclear Organization:** Nucleosome organization and telomere organization.

These results provide strong evidence that the primary transcriptomic hallmark of senescence across all cell types and stressors is the systematic shutdown of genes required for DNA replication and mitotic progression (Fig: `full_dataset_gsea_go.svg`).

## Discussion
Our findings demonstrate that cellular senescence, regardless of the induction method or cell type, converges on a highly conserved program of proliferative arrest. The identification of 21 core DE genes suggests that there is a "minimalist" transcriptomic signature of senescence that transcends biological context. 

The profound downregulation of DNA replication and chromosome segregation pathways observed in our GSEA analysis provides a molecular basis for the permanent growth arrest characteristic of senescent cells. Interestingly, the presence of core upregulated genes like *PTCHD4* suggests these may be useful as pan-senescence biomarkers.

A potential limitation of this study is the variability in sample sizes across different comparison groups. However, the consistency of the "core" signature across eight distinct conditions provides high confidence in these results. Future work should investigate whether the 21 core genes are drivers of senescence or merely downstream consequences of cell cycle arrest.

## Conclusion
In summary, we have characterized the transcriptomic landscape of cellular senescence using a diverse set of human primary cells and stressors. We identified a core signature of differentially expressed genes and confirmed that a global suppression of the mitotic and DNA replication machinery is a universal feature of the senescent state. This study clarifies the extent to which senescence is a converged biological endpoint.

## Figure Legends
- **Figure 1: Principal Component Analysis.** PCA plot showing sample distribution based on Cell Type and Condition. Samples cluster primarily by cell type, with a consistent shift indicating the Senescence condition.
- **Figure 2: Differential Expression Volcano Plots.** PDF plots for each comparison group illustrating genes significantly upregulated (red) and downregulated (blue) in senescent cells compared to controls.
- **Figure 3: Core Signature Overlap.** UpSet plots visualizing the intersection of differentially expressed genes across the eight senescence models, highlighting the core set of universally changed genes.
- **Figure 4: GSEA Enrichment Dotplot.** Visualization of significantly enriched GO terms for the full dataset. The x-axis represents the Normalized Enrichment Score (NES), showing a strong negative enrichment for cell cycle and DNA replication pathways.

## Tables
**Table 1: Core Senescence Signature (Universally DE Genes)**
| Direction | Gene Symbols |
| :--- | :--- |
| **Upregulated** | *CCND3, ARRDC4, PAM, GPR155, TNFRSF10C, PTCHD4* |
| **Downregulated** | *CDKN2C, H1-3, H1-1, NIBAN1, PARP1, CDCA7L, H1-4, SLFN11, CBX2, H2AC20, PTMA, ITPRIPL1, H3C11* |

**Table 2: Top Downregulated Pathways (Full Dataset GSEA)**
| GO Term | NES | p-adjust |
| :--- | :--- | :--- |
| Sister chromatid segregation | -2.73 | $5.5 \times 10^{-9}$ |
| Mitotic sister chromatid segregation | -2.72 | $5.5 \times 10^{-9}$ |
| Chromosome segregation | -2.69 | $5.5 \times 10^{-9}$ |
| DNA replication | -2.61 | $5.5 \times 10^{-9}$ |
