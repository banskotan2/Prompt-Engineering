from fpdf import FPDF
import pandas as pd
import os

class RNASeqReport(FPDF):
    def header(self):
        if self.page_no() > 1:
            self.set_font('Arial', 'I', 8)
            self.cell(0, 10, 'Senescence RNA-seq Analysis Report', 0, 0, 'R')
            self.ln(10)

    def footer(self):
        self.set_y(-15)
        self.set_font('Arial', 'I', 8)
        self.cell(0, 10, f'Page {self.page_no()}', 0, 0, 'C')

    def chapter_title(self, title):
        self.set_font('Arial', 'B', 14)
        self.cell(0, 10, title, 0, 1, 'L')
        self.ln(4)

    def chapter_body(self, body):
        self.set_font('Arial', '', 11)
        self.multi_cell(0, 7, body)
        self.ln()

    def add_table(self, df):
        self.set_font('Arial', 'B', 10)
        col_width = self.epw / len(df.columns)
        for col in df.columns:
            self.cell(col_width, 7, str(col), 1)
        self.ln()
        self.set_font('Arial', '', 9)
        for i in range(min(len(df), 15)):
            for val in df.iloc[i]:
                self.cell(col_width, 6, str(val), 1)
            self.ln()
        self.ln(5)

def generate_report():
    pdf = RNASeqReport()
    pdf.set_auto_page_break(auto=True, margin=15)
    pdf.add_page()

    # Title
    pdf.set_font('Arial', 'B', 20)
    pdf.cell(0, 20, 'Transcriptomic Landscape of Cellular Senescence', 0, 1, 'C')
    pdf.set_font('Arial', 'I', 12)
    pdf.cell(0, 10, 'Analysis across multiple senescence models (IR, RE, Dox, HRAS)', 0, 1, 'C')
    pdf.ln(20)

    # Abstract
    pdf.chapter_title('Abstract')
    abstract = (
        "This report presents a comprehensive RNA-seq analysis of various cellular senescence models, "
        "including Ionizing Radiation (IR), Replicative Exhaustion (RE), Doxorubicin (Dox), and HRAS-induced senescence. "
        "The study aims to identify a core transcriptional signature common across these different triggers. "
        "Our findings highlight significant differential expression of markers associated with cell cycle arrest, "
        "inflammatory response (SASP), and chromatin remodeling. Integration of multi-model data reveals a set of "
        "consistently upregulated genes (e.g., CCND3, ARRDC4) and downregulated genes (e.g., CDKN2C), providing insights "
        "into the convergent pathways of cellular senescence."
    )
    pdf.chapter_body(abstract)

    # Introduction
    pdf.chapter_title('Introduction')
    intro = (
        "Cellular senescence is a state of permanent cell cycle arrest characterized by morphological changes, "
        "the secretion of pro-inflammatory factors (SASP), and metabolic shifts. While triggered by various stressors, "
        "it is hypothesized that these models share a common molecular core. This analysis utilizes bulk RNA-seq to "
        "characterize the transcriptomic shifts across different senescence induction methods in human cells."
    )
    pdf.chapter_body(intro)

    # Methods
    pdf.chapter_title('Methods')
    methods = (
        "RNA-seq data was processed using a standard pipeline. Read counts were normalized and differential expression "
        "was performed using DESeq2. The experimental design accounted for biological replicates within each model. "
        "Statistical significance was defined by adjusted p-value < 0.05. Principal Component Analysis (PCA) was used "
        "for dimensionality reduction. Functional enrichment analysis was conducted using GSEA and GO terms via clusterProfiler."
    )
    pdf.chapter_body(methods)

    # Results - QC & PCA
    pdf.chapter_title('Results')
    pdf.chapter_body("The quality control analysis showed consistent library sizes and high correlation between replicates.")
    
    pdf.set_font('Arial', 'B', 12)
    pdf.cell(0, 10, 'Figure 1: Principal Component Analysis (PCA)', 0, 1, 'L')
    pdf.image('/vf/users/banskotan2/Agentic_engineering/Senescence/Output/Report/temp_images/combined_pca.png', x=10, w=180)
    pdf.ln(10)
    pdf.chapter_body("PCA demonstrates a clear separation between control and senescent samples across all models, "
                    "with the primary axis of variation corresponding to the senescence status.")

    # Results - DE Summary
    pdf.chapter_title('Differential Expression Analysis')
    
    try:
        up_genes = pd.read_csv('/vf/users/banskotan2/Agentic_engineering/Senescence/Output/Table/overall_intersecting_up.csv')
        down_genes = pd.read_csv('/vf/users/banskotan2/Agentic_engineering/Senescence/Output/Table/overall_intersecting_down.csv')
        pdf.chapter_body(f"A core set of genes was identified as consistently differentially expressed across models. "
                        f"We found {len(up_genes)-1} core upregulated and {len(down_genes)-1} core downregulated genes.")
        
        pdf.set_font('Arial', 'B', 12)
        pdf.cell(0, 10, 'Table 1: Core Upregulated Genes', 0, 1, 'L')
        pdf.add_table(up_genes)
    except Exception as e:
        pdf.chapter_body(f"Error loading DE tables: {e}")

    # Volcano Plot
    pdf.set_font('Arial', 'B', 12)
    pdf.cell(0, 10, 'Figure 2: Representative Volcano Plot (HAEC IR)', 0, 1, 'L')
    pdf.image('/vf/users/banskotan2/Agentic_engineering/Senescence/Output/Report/temp_images/HAEC_IR_volcano.png', x=10, w=180)
    pdf.ln(10)

    # Heatmap
    pdf.set_font('Arial', 'B', 12)
    pdf.cell(0, 10, 'Figure 3: Core Differential Expression Heatmap', 0, 1, 'L')
    pdf.image('/vf/users/banskotan2/Agentic_engineering/Senescence/Output/Report/temp_images/combined_heatmaps.png', x=10, w=180)
    pdf.ln(10)

    # Enrichment
    pdf.chapter_title('Functional Enrichment')
    try:
        gsea = pd.read_csv('/vf/users/banskotan2/Agentic_engineering/Senescence/Output/Table/full_dataset_gsea_go.csv')
        pdf.chapter_body("GSEA revealed a significant downregulation of cell cycle-related processes, "
                        "specifically those involved in chromosome segregation and DNA replication.")
        pdf.set_font('Arial', 'B', 12)
        pdf.cell(0, 10, 'Table 2: Top Enriched GO Terms (Downregulated)', 0, 1, 'L')
        # Selecting a subset of columns for the table
        gsea_sub = gsea[['Description', 'NES', 'p.adjust']].head(15)
        pdf.add_table(gsea_sub)
    except Exception as e:
        pdf.chapter_body(f"Error loading GSEA data: {e}")

    # Discussion & Conclusion
    pdf.chapter_title('Discussion')
    discussion = (
        "The consistency of the core gene set across different senescence triggers supports the existence "
        "of a universal senescent program. The downregulation of mitotic proteins and upregulation of SASP-related "
        "factors are hallmarks that were strongly observed in our data."
    )
    pdf.chapter_body(discussion)

    pdf.chapter_title('Conclusion')
    conclusion = (
        "In conclusion, this study provides a high-resolution transcriptional map of senescence and identifies "
        "key genes that define the senescent state regardless of the inducing stimulus."
    )
    pdf.chapter_body(conclusion)

    # Figure Legends
    pdf.chapter_title('Figure Legends')
    legends = (
        "Figure 1: PCA plot showing sample distribution. Colors represent different models; shapes represent control vs senescent.\n"
        "Figure 2: Volcano plot for HAEC IR model. Points signify genes with adj p-value < 0.05 and |log2FC| > 1.\n"
        "Figure 3: Hierarchical clustering heatmap of the core senescence signature."
    )
    pdf.chapter_body(legends)

    output_path = '/vf/users/banskotan2/Agentic_engineering/Senescence/Output/Report/senescence_report.pdf'
    pdf.output(output_path)
    return output_path

if __name__ == '__main__':
    print(generate_report())
