############# INITIALISATION ############# 
## Clean enviroment and load libraries
rm(list = ls())
args = commandArgs(trailingOnly=TRUE)

if(suppressMessages(!require(devtools))){
  install.packages("devtools",repos = "https://mirrors.ebi.ac.uk/CRAN/")
  library(devtools)
}

if(suppressMessages(!require(dplyr))){
  install.packages("dplyr",repos = "https://mirrors.ebi.ac.uk/CRAN/")
  library(dplyr)
}

if(suppressMessages(!require(tibble))){
  install.packages("tibble",repos = "https://mirrors.ebi.ac.uk/CRAN/")
  library(tibble)
}

if(suppressMessages(!require(ComplexHeatmap))){
  install_github("jokergoo/ComplexHeatmap")
  suppressMessages(library(ComplexHeatmap))
}

## Matrix sorting function - mutual exclusivity - https://gist.github.com/armish/564a65ab874a770e2c26
memoSort <- function(M) {
  geneOrder <- sort(rowSums(M), decreasing=TRUE, index.return=TRUE)$ix;
  scoreCol <- function(x) {
    score <- 0;
    for(i in 1:length(x)) {
      if(x[i]) {
        score <- score + 2^(length(x)-i);
      }
    }
    return(score);
  }
  scores <- apply(M[geneOrder, ], 2, scoreCol);
  sampleOrder <- sort(scores, decreasing=TRUE, index.return=TRUE)$ix;
  return(M[geneOrder, sampleOrder]);
}

## Check arguments from CMD line are good
# if(length(args) < 1){
#   stop("## oncogen.R ## - No args - basic syntax: Rscript oncogen.R INPUT_FILE GENE_LIST FILTER_GENE_LIST")
# }

############# DATA INPUT SECTION ############# 
## Read variant_filtering output file 
data.in <- read.table("/home/pss41/variant_analysis/RCC_EMaster_WES_noCandidates/variant_filtering_results.tsv",
                      stringsAsFactors = FALSE,
                      header = TRUE,
                      sep = "\t",
                      quote = "",
                      dec = ".")

## Gene list for filtering
# GENE_LIST <- c("AIP","ALK","APC","ATM","BAP1","BLM","BMPR1A","BRCA1","BRCA2","BRIP1","BUB1B","CDC73","CDH1","CDK4","CDKN1C",
#                "CDKN2A","CEBPA","CEP57","CHEK2","CYLD","DDB2","DICER1","DIS3L2","EGFR","EPCAM","ERCC2","ERCC3","ERCC4","ERCC5",
#                "EXT1","EXT2","EZH2","FANCA","FANCB","FANCC","FANCD2","FANCE","FANCF","FANCG","FANCI","FANCL","FANCM","FH","FLCN",
#                "GATA2","GPC3","HNF1A","HRAS","KIT","MAX","MEN1","MET","MLH1","MSH2","MSH6","MUTYH","NBN","NF1","NF2","NSD1",
#                "PALB2","PHOX2B","PMS2","PMS1","PRF1","PRKAR1A","PTCH1","PTEN","RAD51C","RAD51D","RB1","RECQL4","RET","RHBDF2",
#                "RUNX1","SBDS","SDHAF2","SDHA","SDHB","SDHC","SDHD","SLX4","SMAD4","SMARCB1","STK11","SUFU","TMEM127","TP53","TSC1",
#                "TSC2","VHL","WRN","WT1","XPA","XPC")
GENE_LIST <- c()

FILTER_LIST <- c("TTN")

SORT_TYPE <- "burden"
MUT_TYPE <- "miss"

## Loading, formatting and sorting of clinical info - "-" had to be converted to "." in sample names - stupid R columns...
clinical <- read.table("/home/pss41/RCC-clinic.txt",sep = "\t",stringsAsFactors = FALSE)
clinical$V1 <- gsub(pattern = "-",replacement = ".",clinical$V1)
clinical <- clinical[order(clinical$V2),]
clinical <- clinical %>%
  remove_rownames %>%
  column_to_rownames("V1")

############# FORMATTING SECTION  ############# ############# 

## Filtering to missense variants only
data.missense <- data.in[data.in$CONSEQUENCE == "nonsynonymous SNV",]
## Removing lines that have no variants - should be fixed in variant filtering script
data.missense <- data.missense[!data.missense$HET_val == 0,]

## Replacing "missing values = -9" to 0
data.missense[data.missense == "-9"] <- 0


## Filtering data to gene list provided - if not provided only the top 150 will be plotted
if(length(GENE_LIST) > 0){
  data.missense <- data.missense[data.missense$GENE %in% GENE_LIST,]
}
if(length(FILTER_LIST) > 0){
  data.missense <- data.missense[!data.missense$GENE %in% FILTER_LIST,]
}

## Summing the types of polyphen predictions per gene
polyphen <- data.frame(GENE=as.vector(by(data.missense,data.missense$GENE, function(x) unique(x$GENE))),
                       poly.B=as.vector(by(data.missense,data.missense$GENE, function(x) sum(x$POLYPHEN == "B"))),
                       poly.P=as.vector(by(data.missense,data.missense$GENE, function(x) sum(x$POLYPHEN == "P"))),
                       poly.D=as.vector(by(data.missense,data.missense$GENE, function(x) sum(x$POLYPHEN == "D")))
                       )
## Replacing the rownames with the genes for polyphen summations
polyphen <- polyphen %>%
  remove_rownames %>%
  column_to_rownames("GENE")

## Summing the types of sift predictions per gene
sift <- data.frame(GENE=as.vector(by(data.missense,data.missense$GENE, function(x) unique(x$GENE))),
                   sift.T=as.vector(by(data.missense,data.missense$GENE, function(x) sum(x$SIFT == "T"))),
                   sift.D=as.vector(by(data.missense,data.missense$GENE, function(x) sum(x$SIFT == "D")))
                  )
## Replacing the rownames with the gene for sift summations
sift <- sift %>%
  remove_rownames %>%
  column_to_rownames("GENE")

## Selecting the genotype data from the main data table
data.missense.GT <- data.missense[c(8,29:ncol(data.missense))]

## Summarising genotype data per gene
data.sum.GT <- as.data.frame(data.missense.GT %>%
                        group_by(GENE) %>%
                        summarise_all(funs(sum)))

## Summing the number of affected individuals - that is any sample in which a non-ref HET/HOM variant is present, regardless of total number
data.sum.GT$Aff_unAff <- as.vector(by(data.missense.GT,data.missense.GT$GENE,
                                     function(x) sum(unlist(apply(x,2,
                                                            function(y) unique(1 == y | 2 == y))))))

## Order datatable by descending number of affected individuals
data.sum.GT <- data.sum.GT[order(data.sum.GT$Aff_unAff,decreasing = TRUE),]

## Store the GENE order - used in later ordering steps
data.sum.GT.order <- data.sum.GT$GENE

## Convert GENE column into row names
data.sum.GT <- data.sum.GT %>%
               remove_rownames %>%
               column_to_rownames("GENE")

## Save the Affected counts as a seperate vector as they are removed to form the heatmap matrix - assign the GENE names as row names
Aff_unAff <- as.data.frame(data.sum.GT$Aff_unAff)
rownames(Aff_unAff) <- rownames(data.sum.GT)

## Remove aff_unAff counts, replace all non-zero values as 1, reorder rows by GENE order saved earlier (for safety)
data.FILTER.GT <- data.sum.GT[-ncol(data.sum.GT)]

## Sanity check - filtered matches missense input
colSums(data.missense.GT[-1]) == colSums(data.FILTER.GT)

## Set genotypes and gene order
data.FILTER.GT[data.FILTER.GT != 0] <- 1
data.FILTER.GT <- data.FILTER.GT[data.sum.GT.order,]

############# FILTERING SECTION #############

## Select rows to plot - By row number or By Gene list
if(nrow(data.FILTER.GT) < 150){
  plot_in <- data.FILTER.GT  
} else {
  plot_in <- data.FILTER.GT[1:150,]
}

## Determine sorting type

if(SORT_TYPE == "clinical"){
  clin_row <- rownames(clinical) ## sorting by clinical subtype
  clin_row <- clin_row[clin_row %in% colnames(plot_in)]
  plot_in <- plot_in[clin_row]
} else if(SORT_TYPE == "memo"){
  plot_in <- memoSort(plot_in) ## Sort by memoSort function - applying a mutual exclusivity sort
} else if(SORT_TYPE == "burden"){
  mut_burden <- names(sort(colSums(plot_in),decreasing = T)) ## Sort by greatest number of affected genes
  plot_in <- plot_in[mut_burden]
} else {
  break
}


############# PLOTTING SECTION #############

## Reformatting of pct values for readability
n <- Aff_unAff[rownames(plot_in),]/ncol(plot_in)*100
pct_format <- ifelse(n > 10,as.character(sprintf("%.1f",signif(n,3))),
                  ifelse(n < 1,as.character(sprintf("%.2f",signif(n,2))),as.character(sprintf("%.2f",signif(n,3)))))

## Row annotation of text percentage values of affected counts
H_anno_1 <- rowAnnotation('Pct(%)' = row_anno_text(pct_format,
                                                 #offset = unit(0.25, "npc"),
                                                 gp = gpar(col=c("grey20"),fontsize=6,fontfamily="mono")),
                          show_annotation_name = TRUE,
                          annotation_name_rot = 0,
                          annotation_name_offset = unit(-1.025, "npc"),
                          annotation_name_gp = gpar(fontsize=8,fontfamily="mono"),
                          width = unit(.03, "npc")
                          )

## Row annotation of Barplots for affected counts, polyphen counts, and sift counts
H_anno_2 <- rowAnnotation(Poly = row_anno_barplot(polyphen[rownames(plot_in),], 
                                                          axis = TRUE, 
                                                          axis_side = "bottom",
                                                          border=FALSE,
                                                          axis_gp = gpar(fontsize = 5),
                                                          gp = gpar(col="grey20",lwd=0.5,fill = c("palegreen3","gold2","indianred2"))),
                          Sift = row_anno_barplot(sift[rownames(plot_in),], 
                                                          axis = TRUE,
                                                          axis_gp = gpar(fontsize = 5),
                                                          axis_side = "bottom",
                                                          border=FALSE,
                                                          gp = gpar(col="grey20",lwd=0.5,fill = c("palegreen3","indianred2"))),
                          # General visual improvments to row annotations
                          width = unit(0.2, "npc"),
                          gap = unit(c(.05, .05), "npc"),
                          show_annotation_name = c(TRUE, TRUE),
                          annotation_name_rot = c(0, 0),
                          annotation_name_offset = unit(c(-1.025, -1.025), "npc"),
                          annotation_name_gp = gpar(fontsize=8,fontfamily="mono")
                    )

## Column annotations using sample names
Col_anno_1 <- HeatmapAnnotation(Mutations = anno_barplot(colSums(plot_in,na.rm = TRUE),
                                                     which = "column",
                                                     axis = TRUE,
                                                     axis_side = "right",
                                                     gp = gpar(col="grey20",lwd=0.5,fill = "royalblue3"),
                                                     border = FALSE,
                                                     axis_gp = gpar(fontsize = 5)),
                                Subtypes = clinical[colnames(plot_in),],which = "column",na_col = "grey99",
                                col = list(Subtypes=c("Early"="darkseagreen2","Bilateral"="violet","Family"="coral1","VHL"="cyan3","Control"="grey99")),
                                annotation_legend_param = list(title = "Subtypes",
                                                               nrow=1,
                                                               title_position="leftcenter",
                                                               border = "grey20",
                                                               grid_height = unit(c(2),"mm"),
                                                               grid_width = unit(c(2),"mm"),
                                                               title_gp = gpar(fontsize = 8,fontface = "bold",fontfamily="mono"),
                                                               labels_gp = gpar(fontsize = 8)),
                                annotation_height = unit(c(0.7,0.3), "npc"),
                                show_annotation_name = TRUE,
                                annotation_name_side = "left",
                                annotation_name_gp = gpar(fontsize=8,fontfamily="mono"),
                                gap = unit(.05, "npc")
                                )

## Main heatmap plot of GT/Aff matrix                               
H <- Heatmap(plot_in,
          row_title = "Gene",
          row_title_gp = gpar(fontface="bold",fontsize=12,col="gray20",fontfamily="mono"),
          column_title = "RCC WES dataset - CGP gene list analysis",
          column_title_gp = gpar(fontface="bold",fontsize=12,col="gray20",fontfamily="mono"),
          cluster_rows = FALSE,
          cluster_columns = FALSE,
          rect_gp = gpar(col = "white",lty = 1, lwd = 1),
          col = c("grey98","royalblue3"),
          na_col = "grey98",
          row_names_gp = gpar(col="grey20",fontsize=8,fontfamily="mono"),
          show_column_names = FALSE,
          row_names_side = "left",
          show_heatmap_legend = TRUE,
          heatmap_legend_param = list(title = "Mutation",
                                      labels = c("Ref","Alt"),
                                      legend_direction = "horizontal",
                                      title_position = "leftcenter",
                                      title_gp = gpar(fontsize = 8,fontface = "bold",fontfamily="mono"),
                                      labels_gp = gpar(fontsize = 8),
                                      grid_height = unit(c(2),"mm"),
                                      grid_width = unit(c(2),"mm"),
                                      border = "grey20",
                                      nrow=1),
          bottom_annotation = Col_anno_1
          )

## Heatmap list of main + annotations
H_list <- H + H_anno_1 + H_anno_2

## Custom legend for row annotations
lgd = Legend(at = c("Benign", "Moderate","Pathogenic"),
             title = "Consequence",
             title_position = "leftcenter",
             title_gp = gpar(fontsize = 8,fontface = "bold",fontfamily="mono"),
             labels_gp = gpar(fontsize = 8),
             grid_height = unit(c(2),"mm"),
             grid_width = unit(c(2),"mm"),
             nrow = 1,
             type = "grid",
             border = "grey20",
             legend_gp = gpar(fill = c("palegreen3","gold2","indianred2")))

## Rendering the plot
png(filename = "oncogen_plot_genefirst.png",width = (8 + ifelse(ncol(plot_in) > 100,ncol(plot_in)/75,0)),
                                            height = 6 + (0.5*((nrow(plot_in)/10)-1)),
                                            units = "in",
                                            res = 600)
draw(H_list,
     padding = unit(c(0.01, 0, 0, 0.01), "npc"),
     heatmap_legend_side = "bottom",
     annotation_legend_list = list(lgd),
     annotation_legend_side = "bottom"
)

dev.off()


