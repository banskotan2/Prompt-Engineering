#!/usr/bin/env python3
"""Build the cellular senescence reanalysis paper as an embedded-figure PDF."""

from pathlib import Path
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import (
    BaseDocTemplate, PageTemplate, Frame, Paragraph, Spacer, Image,
    Table, TableStyle, PageBreak, KeepTogether
)
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfbase import pdfmetrics
from PIL import Image as PILImage


ROOT = Path(__file__).resolve().parents[2]
PAPER_DIR = ROOT / "Codex" / "Paper"
TMP_DIR = PAPER_DIR / "tmp"
OUT_PDF = PAPER_DIR / "Cellular_Senescence_Paper.pdf"


def register_fonts():
    candidates = {
        "Times-Roman": "/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf",
        "Times-Bold": "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf",
        "Helvetica": "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "Helvetica-Bold": "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    }
    for name, path in candidates.items():
        if Path(path).exists():
            pdfmetrics.registerFont(TTFont(name, path))
    pdfmetrics.registerFontFamily(
        "Times-Roman", normal="Times-Roman", bold="Times-Bold",
        italic="Times-Roman", boldItalic="Times-Bold"
    )
    pdfmetrics.registerFontFamily(
        "Helvetica", normal="Helvetica", bold="Helvetica-Bold",
        italic="Helvetica", boldItalic="Helvetica-Bold"
    )


register_fonts()

styles = getSampleStyleSheet()
styles.add(ParagraphStyle(
    name="PaperTitle", parent=styles["Title"], fontName="Times-Bold",
    fontSize=19, leading=23, alignment=TA_CENTER, spaceAfter=15,
    textColor=colors.HexColor("#17324D")
))
styles.add(ParagraphStyle(
    name="Subtitle", parent=styles["Normal"], fontName="Helvetica",
    fontSize=10.5, leading=14, alignment=TA_CENTER, textColor=colors.HexColor("#44546A")
))
styles.add(ParagraphStyle(
    name="Section", parent=styles["Heading1"], fontName="Times-Bold",
    fontSize=15, leading=18, spaceBefore=12, spaceAfter=7,
    textColor=colors.HexColor("#17324D"), keepWithNext=True
))
styles.add(ParagraphStyle(
    name="Subsection", parent=styles["Heading2"], fontName="Helvetica-Bold",
    fontSize=10.5, leading=13, spaceBefore=9, spaceAfter=4,
    textColor=colors.HexColor("#254F6E"), keepWithNext=True
))
styles.add(ParagraphStyle(
    name="BodyPaper", parent=styles["BodyText"], fontName="Times-Roman",
    fontSize=9.25, leading=12.7, alignment=TA_JUSTIFY,
    spaceAfter=7, allowWidows=0, allowOrphans=0
))
styles.add(ParagraphStyle(
    name="AbstractBody", parent=styles["BodyPaper"], fontSize=9.5,
    leading=13, leftIndent=20, rightIndent=20
))
styles.add(ParagraphStyle(
    name="Caption", parent=styles["BodyText"], fontName="Helvetica",
    fontSize=7.7, leading=10.2, alignment=TA_LEFT, spaceBefore=4,
    spaceAfter=9, textColor=colors.HexColor("#263238")
))
styles.add(ParagraphStyle(
    name="TableText", parent=styles["BodyText"], fontName="Helvetica",
    fontSize=7.2, leading=9
))
styles.add(ParagraphStyle(
    name="Reference", parent=styles["BodyText"], fontName="Times-Roman",
    fontSize=7.6, leading=10, leftIndent=14, firstLineIndent=-14, spaceAfter=3
))
styles.add(ParagraphStyle(
    name="Running", parent=styles["BodyText"], fontName="Helvetica",
    fontSize=7, leading=8, textColor=colors.HexColor("#667788")
))


def page_header_footer(canvas, doc):
    canvas.saveState()
    width, height = letter
    canvas.setStrokeColor(colors.HexColor("#B0BEC5"))
    canvas.setLineWidth(0.4)
    canvas.line(0.70 * inch, height - 0.54 * inch, width - 0.70 * inch, height - 0.54 * inch)
    canvas.setFont("Helvetica", 7)
    canvas.setFillColor(colors.HexColor("#607D8B"))
    canvas.drawString(0.70 * inch, height - 0.43 * inch, "Cellular senescence transcriptome reanalysis")
    canvas.drawRightString(width - 0.70 * inch, 0.42 * inch, f"Page {doc.page}")
    canvas.restoreState()


class PaperDocTemplate(BaseDocTemplate):
    def __init__(self, filename, **kw):
        super().__init__(filename, **kw)
        frame = Frame(
            self.leftMargin, self.bottomMargin, self.width, self.height,
            id="normal", leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0
        )
        self.addPageTemplates(PageTemplate(id="paper", frames=[frame], onPage=page_header_footer))


def P(text, style="BodyPaper"):
    return Paragraph(text, styles[style])


def section(title):
    return P(title, "Section")


def subsection(title):
    return P(title, "Subsection")


def figure(path, number, caption, max_height=5.7 * inch):
    path = Path(path)
    if not path.exists():
        raise FileNotFoundError(path)
    with PILImage.open(path) as im:
        w, h = im.size
    max_width = 7.05 * inch
    scale = min(max_width / w, max_height / h)
    img = Image(str(path), width=w * scale, height=h * scale)
    img.hAlign = "CENTER"
    cap = P(f"<b>Figure {number}.</b> {caption}", "Caption")
    return KeepTogether([img, cap])


def make_table(data, col_widths, header=True):
    cooked = [[P(str(cell), "TableText") for cell in row] for row in data]
    t = Table(cooked, colWidths=col_widths, repeatRows=1 if header else 0, hAlign="CENTER")
    style = [
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#B0BEC5")),
        ("LEFTPADDING", (0, 0), (-1, -1), 4),
        ("RIGHTPADDING", (0, 0), (-1, -1), 4),
        ("TOPPADDING", (0, 0), (-1, -1), 3),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F4F7F9")]),
    ]
    if header:
        style += [
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#DCE8F1")),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.HexColor("#17324D")),
        ]
    t.setStyle(TableStyle(style))
    return t


story = []
story += [
    Spacer(1, 0.45 * inch),
    P("Shared and Context-Dependent Transcriptional Programs Across Eight Models of Human Cellular Senescence", "PaperTitle"),
    P("A reproducible reanalysis of bulk RNA-sequencing data from human fibroblast and endothelial cell models", "Subtitle"),
    Spacer(1, 0.12 * inch),
    P("Prepared from the analysis, tables, scripts, and figures in the <i>Codex</i> folder", "Subtitle"),
    P("3 August 2026", "Subtitle"),
    Spacer(1, 0.28 * inch),
]

story.append(section("Abstract"))
story.append(P(
    "Cellular senescence is a durable stress response characterized by proliferative arrest and extensive remodeling of gene expression, but no single molecular marker identifies every senescent state. We reanalyzed 37 bulk RNA-sequencing samples spanning eight human senescence models in aortic and umbilical-vein endothelial cells and IMR-90 and WI-38 fibroblasts. Senescence was induced by ionizing radiation, replicative exhaustion, oncogenic HRAS<super>G12V</super>, or doxorubicin. A pooled DESeq2 model adjusted for cell type identified 3,220 genes at Benjamini-Hochberg false-discovery rate (FDR) &lt; 0.05, including 1,895 upregulated and 1,325 downregulated genes. Gene-set enrichment showed positive immune, inflammatory, chemokine, transport, and autophagy programs and negative DNA-replication, mitotic, DNA-repair, chromatin, and RNA-processing programs. Separate models yielded 1,392-10,222 significant genes, demonstrating large context effects. Nevertheless, 12 genes were significantly upregulated and 20 were significantly downregulated in every comparison. PTCHD4 increased in all eight models (log<sub>2</sub> fold change 1.51-4.03), whereas CDKN1A, CDKN2A, MKI67, LMNB1, GDF15, and PURPL were not universally significant or directionally consistent. These findings support a conserved arrest-and-inflammatory axis while showing that senescence is better represented by multi-feature signatures than by a single canonical marker. The results reproduce major conclusions of the originating study under a stricter FDR threshold and a distinct count-modeling framework [5,8].", "AbstractBody"
))

story.append(section("Introduction"))
story.append(P(
    "Replicative senescence was first recognized as the finite proliferative capacity of cultured human diploid cells [1]. The concept now encompasses a durable cell-cycle arrest elicited by telomere attrition, persistent DNA damage, oncogenic signaling, oxidative and metabolic stress, and selected cytotoxic treatments [2-5]. Senescent cells remain metabolically active and may acquire enlarged morphology, lysosomal senescence-associated beta-galactosidase activity, persistent DNA-damage signaling, altered chromatin, and activation of the p53-CDKN1A and CDKN2A-RB tumor-suppressor axes [3-5]. Because none of these properties is uniquely present in every senescent cell, current consensus favors combinations of markers and functional evidence rather than a single test [5,6]."
))
story.append(P(
    "Senescence has context-dependent physiological and pathological roles. Transient senescence can restrict propagation of damaged or oncogene-expressing cells and participate in development, remodeling, and wound repair, whereas persistent senescent cells can disrupt tissues through loss of regenerative capacity and paracrine signaling [2,5,7]. A prominent non-cell-autonomous feature is the senescence-associated secretory phenotype (SASP), a variable mixture of cytokines, chemokines, growth factors, proteases, and extracellular-matrix regulators [9,10]. Genetic clearance of p16<super>Ink4a</super>-positive cells improved healthspan and lifespan measures in mice, providing causal evidence that at least some senescent-cell populations contribute to age-associated dysfunction [11]."
))
story.append(P(
    "The transcriptional diversity of senescence complicates biomarker discovery. Cell lineage, inducer, dose, time after induction, culture environment, and the depth of arrest can all alter the observed RNA program [5,6,8,10]. Casella and colleagues addressed this problem by profiling eight senescence models in WI-38 and IMR-90 fibroblasts, human umbilical-vein endothelial cells (HUVECs), and human aortic endothelial cells (HAECs). Their edgeR analysis at FDR &lt; 0.15 reported 50 increased and 18 reduced transcripts shared across models and identified PTCHD4 and PURPL among a compact discriminatory signature [8]."
))
story.append(P(
    "Here, the same count matrix was reanalyzed using DESeq2, a stricter FDR &lt; 0.05 threshold, a pooled model controlling for cell type, eight within-model contrasts, preranked Gene Ontology (GO) enrichment, cross-model intersections, and directed examination of established or proposed markers [8,12-16]. The objectives were to quantify shared and model-specific transcriptional responses, identify biological processes altered across the cohort, and assess how reliably commonly used markers behave across distinct senescent states."
))

story.append(section("Results"))
story.append(subsection("Experimental diversity and global expression structure"))
story.append(P(
    "The dataset contained 60,605 count-matrix features measured in 37 libraries: 17 controls and 20 senescent samples. The eight contrasts comprised HAEC ionizing radiation (IR; n=5), HUVEC IR (n=6), IMR-90 IR (n=4), IMR-90 replicative exhaustion (n=4), WI-38 doxorubicin (n=8), WI-38 HRAS<super>G12V</super> (n=4), WI-38 IR (n=4), and WI-38 replicative exhaustion (n=4). Two IMR-90 proliferating samples served as controls for both IMR-90 contrasts, so per-comparison sample counts sum to 39 while the unique cohort contains 37 libraries [8]."
))
story.append(P(
    "Variance-stabilized principal-component analysis separated control and senescent samples along PC1 in each comparison, including every cell lineage and induction mechanism (Figure 1). The sign of a principal component is arbitrary, but the condition-specific displacement was consistent within panels. Separation was especially pronounced for IMR-90 IR, IMR-90 replicative exhaustion, WI-38 HRAS, WI-38 IR, and WI-38 replicative exhaustion, whereas WI-38 doxorubicin showed a smaller centroid displacement. Because these PCAs were fitted separately, axis percentages and coordinate scales should not be compared quantitatively across panels [12]."
))
story.append(figure(
    TMP_DIR / "figure1_pca.png", 1,
    "Principal-component analysis of the eight senescence comparisons. Points represent variance-stabilized RNA-seq profiles; blue denotes control and red denotes senescent samples. Each panel was calculated independently, and sample labels correspond to Sequence Read Archive accessions. The shared IMR-90 controls appear in both the IR and replicative-exhaustion panels. Source: Codex DESeq2 analysis of GSE130727 [8,12].", 4.25 * inch
))

story.append(subsection("A pooled, cell-adjusted senescence program"))
story.append(P(
    "After filtering, 24,914 named genes were tested in the pooled design (~ Cell + Condition). Of these, 3,220 (12.9%) met FDR &lt; 0.05: 1,895 increased and 1,325 decreased in senescent relative to control cells. Strongly supported increases included SLCO2B1 (log<sub>2</sub>FC 4.65; FDR 1.2x10<super>-20</super>), PTCHD4 (2.74; 1.4x10<super>-20</super>), PINCR (3.58; 3.3x10<super>-18</super>), ARRDC4 (2.36; 6.7x10<super>-17</super>), and CCND2 (2.94; 9.3x10<super>-14</super>). Strong decreases included ITPRIPL1 (-2.23; 2.8x10<super>-18</super>), GPSM2 (-1.33; 1.0x10<super>-11</super>), H1-4 (-2.15; 3.6x10<super>-11</super>), NCAPH (-2.14; 5.6x10<super>-11</super>), and CENPF (-2.14; 6.8x10<super>-11</super>) (Figure 2)."
))
story.append(figure(
    TMP_DIR / "figure2_volcano.png", 2,
    "Pooled differential expression for senescent versus control samples after adjustment for cell type. Red and blue points meet FDR &lt; 0.05 and have positive and negative log<sub>2</sub> fold change, respectively; gray points do not meet the FDR threshold. Labels identify the five smallest nominal p-values in each significant direction. The y-axis displays nominal p-value, while significance categories use adjusted p-value. Source: Codex analysis [12,13].", 4.55 * inch
))

story.append(subsection("Functional enrichment links arrest to inflammatory and stress-adaptive programs"))
story.append(P(
    "Preranked GO Biological Process enrichment resolved two broad poles of the pooled senescence response (Figure 3). Positively enriched terms included immune response (normalized enrichment score [NES] 2.35; FDR 1.2x10<super>-8</super>), inflammatory response (NES 1.88; FDR 4.1x10<super>-8</super>), chemokine-mediated signaling (NES 2.28; FDR 2.3x10<super>-6</super>), response to virus (NES 2.07; FDR 4.0x10<super>-6</super>), transmembrane transport (NES 2.25; FDR 1.2x10<super>-8</super>), endosomal lumen acidification (NES 2.27; FDR 7.2x10<super>-6</super>), and autophagy (NES 1.89; FDR 1.1x10<super>-5</super>). This pattern is compatible with SASP-associated inflammatory signaling and lysosomal remodeling, although RNA enrichment does not by itself demonstrate secretion or pathway flux [5,9,10]."
))
story.append(P(
    "Negatively enriched terms were dominated by proliferation and genome maintenance: DNA replication (NES -3.24), mitotic cell cycle (-3.14), mitotic sister-chromatid segregation (-2.91), DNA repair (-2.99), homologous-recombination repair (-2.79), nucleosome assembly (-3.18), chromatin organization (-2.80), mRNA splicing (-2.45), and mRNA processing (-2.41); each had FDR 1.2x10<super>-8</super>. The concerted suppression of these gene sets provides transcriptomic evidence of proliferative withdrawal, but stable arrest remains a phenotype that should be verified experimentally [3,5,6]."
))
story.append(figure(
    TMP_DIR / "figure3_gsea.png", 3,
    "Top GO Biological Process gene sets from preranked enrichment of the pooled DESeq2 Wald statistics. Positive NES indicates enrichment among genes increased in senescence; negative NES indicates enrichment among genes decreased in senescence. Point area represents gene-set size and color represents Benjamini-Hochberg adjusted p-value. The plot shows the 20 most significant terms. Source: Codex fgsea analysis using GO annotations [14-16].", 5.15 * inch
))

story.append(subsection("Differential-expression burden varies by model"))
summary_data = [
    ["Comparison", "n", "Named genes", "FDR < 0.05", "Up", "Down"],
    ["HAEC IR", "5", "18,708", "7,945", "3,650", "4,295"],
    ["HUVEC IR", "6", "19,184", "8,145", "3,616", "4,529"],
    ["IMR-90 IR", "4", "19,049", "10,222", "5,899", "4,323"],
    ["IMR-90 replicative exhaustion", "4", "18,845", "9,567", "5,526", "4,041"],
    ["WI-38 doxorubicin", "8", "21,303", "1,392", "819", "573"],
    ["WI-38 HRAS", "4", "18,316", "8,105", "4,837", "3,268"],
    ["WI-38 IR", "4", "19,841", "4,606", "2,447", "2,159"],
    ["WI-38 replicative exhaustion", "4", "19,252", "5,431", "2,607", "2,824"],
]
story.append(P(
    "Separate DESeq2 models revealed a sevenfold range in the number of significant genes (Table 1). WI-38 doxorubicin produced the smallest response (1,392 genes), whereas IMR-90 IR produced the largest (10,222 genes). Sample size alone did not explain this pattern: the doxorubicin comparison had eight samples, the largest within-model cohort, but the fewest significant genes. The result instead reflects some combination of effect magnitude, replicate variability, cell state, and the specific control-treatment pairing [8,12]."
))
story.append(P("<b>Table 1.</b> Differential-expression summary for eight within-model contrasts.", "Caption"))
story.append(make_table(summary_data, [1.75*inch, .38*inch, .78*inch, .72*inch, .54*inch, .54*inch]))
story.append(Spacer(1, 7))

story.append(subsection("Canonical markers are not universal"))
story.append(P(
    "The marker panel exposed substantial heterogeneity (Figure 4). PTCHD4 was significantly increased in all eight models, with log<sub>2</sub>FC values from 1.51 in WI-38 HRAS to 4.03 in WI-38 IR. CDKN1A increased significantly in six models but not WI-38 doxorubicin or WI-38 replicative exhaustion. CDKN2A increased significantly in only four models and was essentially unchanged in WI-38 IR and replicative exhaustion. PURPL was significantly increased in seven evaluable models except WI-38 doxorubicin; it was absent from the named HUVEC result table. GDF15 increased significantly in six models but not IMR-90 replicative exhaustion or WI-38 doxorubicin."
))
story.append(P(
    "Markers of proliferation and nuclear-lamina integrity were also context dependent. MKI67 decreased significantly in six models, but increased in IMR-90 IR and was not significant in IMR-90 replicative exhaustion. LMNB1 decreased significantly in six models but was unchanged in IMR-90 IR and only modestly reduced in IMR-90 replicative exhaustion. These exceptions reinforce that senescence classification should integrate arrest, structural, damage, lysosomal, and secretory features; LMNB1 loss is useful but not universal, and p16/p21 transcript abundance alone is insufficient [5,6,8,17]."
))
story.append(figure(
    TMP_DIR / "figure4_markers.png", 4,
    "Expression of selected senescence-associated genes across eight comparisons. Fill indicates log<sub>2</sub> fold change (senescent/control); point size indicates -log<sub>10</sub> nominal p-value. The panel includes PTCHD4, CDKN1A, CDKN2A, PURPL, GDF15, MKI67, LMNB1, and members of the MCM replication-licensing family. Missing points indicate genes absent from the named-gene result table. Source: Codex analysis; marker interpretation follows consensus and primary studies [5,6,8,17].", 5.65 * inch
))

story.append(subsection("A stringent cross-model core is smaller than the original signature"))
story.append(P(
    "Intersection analysis at FDR &lt; 0.05 identified 12 genes significantly increased in all eight models: ARRDC4, CCND3, CLDN1, GPR155, PAM, PTCHD4, RND3, SARAF, TMED4, TMEM59, TNFRSF10C, and TNFSF13B (Figure 5). It also identified 20 genes significantly decreased in every model: CBX2, CDCA7L, CDKN2C, EML4, GLUL, H1-1, H1-3, H1-4, H2AC20, H2BC9, H3C11, HNRNPH1, ITPRIPL1, LIG3, NIBAN1, PARP1, PHB2, PTMA, SLFN11, and VSIG10 (Figure 6). The downregulated core contains multiple histone genes and chromatin-associated factors, consistent with the pooled chromatin and nucleosome enrichment results [8]."
))
story.append(figure(
    TMP_DIR / "figure5_upset_up.png", 5,
    "Cross-model intersections of significantly upregulated genes (FDR &lt; 0.05; log<sub>2</sub>FC &gt; 0). Horizontal bars give each model's significant set size; the matrix and vertical bars give intersection membership and size. Twelve genes occur in the eight-way intersection. Source: Codex analysis [13].", 4.55 * inch
))
story.append(figure(
    TMP_DIR / "figure6_upset_down.png", 6,
    "Cross-model intersections of significantly downregulated genes (FDR &lt; 0.05; log<sub>2</sub>FC &lt; 0). Twenty genes occur in the eight-way intersection. Source: Codex analysis [13].", 4.55 * inch
))

story.append(section("Methods"))
story.append(subsection("Dataset and experimental groups"))
story.append(P(
    "The analysis used the count matrix, sample metadata, and Homo sapiens GRCh38 Ensembl release 104 annotation supplied in the project root. The libraries correspond to GEO accession GSE130727 and SRA accessions SRR9016146-SRR9016182 [8]. The originating experiments used proliferating or matched control cells and senescent HAEC, HUVEC, IMR-90, and WI-38 cultures generated by IR, replicative exhaustion, doxorubicin exposure, or HRAS<super>G12V</super> expression. Casella et al. describe culture conditions, senescence validation, RNA extraction, rRNA depletion, and paired-end Illumina sequencing [8]. This work is a computational reanalysis and did not repeat wet-laboratory validation."
))
story.append(subsection("Input validation and preprocessing"))
story.append(P(
    "The workflow verified that count-matrix columns matched metadata filenames, gene and sample identifiers were unique, counts were finite non-negative integers, all samples were labeled Control or Senescent, and every comparison contained both conditions. Genes with counts of at least 10 in at least two samples were retained. Ensembl stable IDs were mapped to gene names and descriptions through the supplied release-104 annotation; results lacking a nonempty gene symbol were excluded from named-gene tables. Ensembl provides stable identifiers and curated genome annotation, although annotation changes across releases can alter mappings [18]."
))
story.append(subsection("Differential expression and visualization"))
story.append(P(
    "Raw integer counts were modeled with DESeq2 version 1.50.2 in R 4.5.2 [12]. The pooled analysis used the design ~ Cell + Condition, thereby estimating the senescent-control contrast while accounting for cell-line differences. Each of the eight comparisons used ~ Condition. DESeq2 fit negative-binomial generalized linear models, estimated size factors and dispersions, and tested the Senescent-versus-Control coefficient with Wald statistics [12]. Reported log<sub>2</sub> fold changes are unshrunken DESeq2 result estimates. P-values were adjusted by the Benjamini-Hochberg method, and FDR &lt; 0.05 defined significance [13]. No additional absolute fold-change threshold was imposed."
))
story.append(P(
    "Variance-stabilizing transformation was applied with blind=FALSE for visualization. PCA used DESeq2 plotPCA; within-comparison heat maps (not reproduced here) used row-standardized values for the 50 genes with the smallest nominal p-values. Volcano plots used log<sub>2</sub> fold change and -log<sub>10</sub> nominal p-value, with color determined by adjusted-p-value significance and effect direction. Because labels were selected by smallest nominal p-value, the volcano y-axis and label ranking should not be read as independent multiplicity-adjusted evidence [12,13]."
))
story.append(subsection("Gene-set enrichment, overlap, and markers"))
story.append(P(
    "For GO Biological Process enrichment, finite DESeq2 Wald statistics were keyed by unique gene symbol, sorted from positive to negative, and analyzed with fgseaMultilevel (fgsea 1.36.2) using gene sets of 10-500 genes and a fixed random seed of 1 [14]. Gene-to-GO mappings came from org.Hs.eg.db and GO.db; terms at FDR &lt; 0.05 were retained [15,16]. Positive NES denotes enrichment toward genes increased in senescence; negative NES denotes enrichment toward genes decreased in senescence. GO terms are overlapping and hierarchically related, so neighboring terms do not represent independent mechanisms [16]."
))
story.append(P(
    "For each within-model result, significant up- and downregulated gene-symbol sets were formed using FDR &lt; 0.05 and fold-change sign. UpSet intersections were generated with UpSetR 1.4.0, and exact eight-way intersections were exported. The directed marker panel contained PTCHD4, CDKN1A, CDKN2A, PURPL, GDF15, MKI67, LMNB1, and every named gene matching the MCM family pattern. Dot size represents nominal-p-value evidence and fill represents effect magnitude and direction; statistical significance was always assessed from adjusted p-values."
))
story.append(subsection("Reproducibility and provenance"))
story.append(P(
    "All numerical statements and figures in this paper derive from files under Codex/Output. The executable workflow is preserved in Codex/Output/Script; machine-readable results are in Codex/Output/Table; figures are in Codex/Output/Plot; and session information is in Codex/Output/Report. The recorded software included ggplot2 4.0.3, pheatmap 1.0.13, ggrepel 0.9.8, fgsea 1.36.2, org.Hs.eg.db 3.22.0, GO.db 3.22.0, UpSetR 1.4.0, ComplexHeatmap 2.26.1, and associated dependencies. Final workflow QC found all 43 expected figures present and above the predefined minimum file size."
))

story.append(section("Discussion"))
story.append(P(
    "This reanalysis resolves a conserved transcriptional backbone of cellular senescence against substantial model-specific variation. The pooled response combines repression of DNA replication, mitosis, chromosome segregation, homologous-recombination repair, and chromatin organization with activation of immune, inflammatory, chemokine, transport, endolysosomal, and autophagy programs. That architecture is consistent with a durable proliferative arrest coupled to extensive cell-state remodeling and SASP-related signaling [3-6,9,10]. The enrichment results should nevertheless be interpreted as coordinated RNA abundance changes rather than direct measurements of protein secretion, lysosomal activity, DNA-repair capacity, or irreversible arrest."
))
story.append(P(
    "The strongest practical conclusion is that canonical markers are conditional. CDKN2A, CDKN1A, MKI67, LMNB1, GDF15, and PURPL each failed universality under the present model and threshold, and two markers even moved in an unexpected direction in IMR-90 IR. These findings do not invalidate the markers; they show that a gene can be mechanistically important or diagnostically useful without changing at the mRNA level in every context. Protein abundance, post-translational regulation, cell-cycle composition, temporal sampling, and distinct arrest circuits can decouple transcript behavior from phenotype [5,6,8,17]. A robust experimental diagnosis should therefore combine proliferation or re-entry assays with multiple molecular features selected for the tissue and inducer."
))
story.append(P(
    "PTCHD4 was an unusually stable positive marker in this dataset, and it belongs to the compact transcript set highlighted by the originating study [8]. However, its cross-model consistency in the same cohort is not independent external validation. PTCHD4 should be tested prospectively across additional primary cell types, time courses, quiescent and terminally differentiated controls, disease tissues, and single-cell measurements before it is treated as a general senescence biomarker. The same caution applies to the 32-gene stringent core: intersection criteria favor consistent, well-powered signals and can exclude genuine biology that is absent, weak, or variable in one model."
))
story.append(P(
    "The present 12-up/20-down core is smaller and differently composed than the original 50-up/18-down signature [8]. This is expected because the original study used edgeR, TMM normalization, staged intersections, and FDR &lt; 0.15, whereas this workflow used DESeq2, per-comparison filtering, and FDR &lt; 0.05 [8,12,13]. The stricter result should not be framed as correcting the earlier analysis; it answers a narrower question about genes that remain significant in every contrast under a more conservative, uniform pipeline. Agreement on PTCHD4, histone-linked decreases, inflammatory programs, and marker heterogeneity indicates that several major conclusions are robust to analytic choices [8]."
))
story.append(P(
    "Several design limitations constrain inference. Most contrasts contained only two or three replicates per condition, the cohort combined endothelial and fibroblast lineages, and the pooled model included cell type but not a cell-by-condition interaction. The two IMR-90 controls were reused across related contrasts, so cross-comparison intersections are not based on fully independent experiments. Batch, sequencing run, sex, donor, and time-after-induction effects could not be estimated from the available design. Bulk RNA-seq averages heterogeneous cells and cannot distinguish a uniform shift from a changing mixture of proliferating, arrested, dying, or incompletely senescent cells. Finally, the analysis is observational and cannot establish that shared genes cause arrest or SASP production [5,6,8]."
))
story.append(P(
    "Future work should combine larger factorial designs with longitudinal sampling, matched quiescence and apoptosis controls, single-cell or spatial transcriptomics, secretome proteomics, chromatin profiling, and functional perturbation. Such experiments could distinguish early trigger-specific responses from stable maintenance programs and determine whether the stringent core predicts senescence in vivo. Because SASP composition varies by lineage and inducer, joint models of arrest, damage, structure, lysosomal function, and secretory output are likely to outperform single-gene classifiers [5,6,10]."
))

story.append(section("Conclusion"))
story.append(P(
    "Across eight human cell-culture models, cellular senescence was associated with a shared transcriptional axis of proliferative shutdown, altered genome and chromatin programs, and increased immune-inflammatory and endolysosomal signaling. Yet the magnitude of differential expression varied sevenfold across models, and most conventional markers were not universal. A stringent intersection yielded 12 consistently increased and 20 consistently decreased genes, with PTCHD4 emerging as the most stable assayed positive marker. These data support a multi-marker, context-aware definition of senescence and provide a reproducible foundation for validation in independent cells and tissues [5,6,8]."
))

story.append(section("References"))
references = [
    "[1] Hayflick L, Moorhead PS. The serial cultivation of human diploid cell strains. <i>Experimental Cell Research</i>. 1961;25:585-621. doi:10.1016/0014-4827(61)90192-6.",
    "[2] Serrano M, Lin AW, McCurrach ME, Beach D, Lowe SW. Oncogenic ras provokes premature cell senescence associated with accumulation of p53 and p16INK4a. <i>Cell</i>. 1997;88:593-602. doi:10.1016/S0092-8674(00)81902-9.",
    "[3] d'Adda di Fagagna F, Reaper PM, Clay-Farrace L, et al. A DNA damage checkpoint response in telomere-initiated senescence. <i>Nature</i>. 2003;426:194-198. doi:10.1038/nature02118.",
    "[4] Hernandez-Segura A, Nehme J, Demaria M. Hallmarks of cellular senescence. <i>Trends in Cell Biology</i>. 2018;28:436-453. doi:10.1016/j.tcb.2018.02.001.",
    "[5] Gorgoulis V, Adams PD, Alimonti A, et al. Cellular senescence: defining a path forward. <i>Cell</i>. 2019;179:813-827. doi:10.1016/j.cell.2019.10.005.",
    "[6] Hernandez-Segura A, de Jong TV, Melov S, Guryev V, Campisi J, Demaria M. Unmasking transcriptional heterogeneity in senescent cells. <i>Current Biology</i>. 2017;27:2652-2660.e4. doi:10.1016/j.cub.2017.07.033.",
    "[7] Demaria M, Ohtani N, Youssef SA, et al. An essential role for senescent cells in optimal wound healing through secretion of PDGF-AA. <i>Developmental Cell</i>. 2014;31:722-733. doi:10.1016/j.devcel.2014.11.012.",
    "[8] Casella G, Munk R, Kim KM, Piao Y, De S, Abdelmohsen K, Gorospe M. Transcriptome signature of cellular senescence. <i>Nucleic Acids Research</i>. 2019;47:7294-7305. doi:10.1093/nar/gkz555. Dataset: GEO GSE130727, BioProject PRJNA541183.",
    "[9] Coppe JP, Patil CK, Rodier F, et al. Senescence-associated secretory phenotypes reveal cell-nonautonomous functions of oncogenic RAS and the p53 tumor suppressor. <i>PLoS Biology</i>. 2008;6:e301. doi:10.1371/journal.pbio.0060301.",
    "[10] Basisty N, Kale A, Jeon OH, et al. A proteomic atlas of senescence-associated secretomes for aging biomarker development. <i>PLoS Biology</i>. 2020;18:e3000599. doi:10.1371/journal.pbio.3000599.",
    "[11] Baker DJ, Childs BG, Durik M, et al. Naturally occurring p16Ink4a-positive cells shorten healthy lifespan. <i>Nature</i>. 2016;530:184-189. doi:10.1038/nature16932.",
    "[12] Love MI, Huber W, Anders S. Moderated estimation of fold change and dispersion for RNA-seq data with DESeq2. <i>Genome Biology</i>. 2014;15:550. doi:10.1186/s13059-014-0550-8.",
    "[13] Benjamini Y, Hochberg Y. Controlling the false discovery rate: a practical and powerful approach to multiple testing. <i>Journal of the Royal Statistical Society B</i>. 1995;57:289-300. doi:10.1111/j.2517-6161.1995.tb02031.x.",
    "[14] Korotkevich G, Sukhov V, Budin N, Shpak B, Artyomov MN, Sergushichev A. Fast gene set enrichment analysis. <i>bioRxiv</i>. 2021. doi:10.1101/060012.",
    "[15] Subramanian A, Tamayo P, Mootha VK, et al. Gene set enrichment analysis: a knowledge-based approach for interpreting genome-wide expression profiles. <i>Proceedings of the National Academy of Sciences USA</i>. 2005;102:15545-15550. doi:10.1073/pnas.0506580102.",
    "[16] Gene Ontology Consortium. The Gene Ontology resource: enriching a GOld mine. <i>Nucleic Acids Research</i>. 2021;49:D325-D334. doi:10.1093/nar/gkaa1113.",
    "[17] Freund A, Laberge RM, Demaria M, Campisi J. Lamin B1 loss is a senescence-associated biomarker. <i>Molecular Biology of the Cell</i>. 2012;23:2066-2075. doi:10.1091/mbc.E11-10-0884.",
    "[18] Howe KL, Achuthan P, Allen J, et al. Ensembl 2021. <i>Nucleic Acids Research</i>. 2021;49:D884-D891. doi:10.1093/nar/gkaa942.",
]
for ref in references:
    story.append(P(ref, "Reference"))


def build():
    TMP_DIR.mkdir(parents=True, exist_ok=True)
    doc = PaperDocTemplate(
        str(OUT_PDF), pagesize=letter,
        rightMargin=0.70 * inch, leftMargin=0.70 * inch,
        topMargin=0.66 * inch, bottomMargin=0.62 * inch,
        title="Shared and Context-Dependent Transcriptional Programs Across Eight Models of Human Cellular Senescence",
        author="Computational reanalysis prepared from Codex project outputs",
        subject="Cellular senescence RNA-seq reanalysis",
        creator="ReportLab"
    )
    doc.build(story)
    print(OUT_PDF)


if __name__ == "__main__":
    build()
