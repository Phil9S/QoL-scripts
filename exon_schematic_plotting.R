## Environment clean up
rm(list=ls())
require(methods)
## If statement library loading to confirm they are isntalled
if(!require(ggplot2)){
  install.packages("ggplot2",repos = "https://mirrors.ebi.ac.uk/CRAN/")
  library(ggplot2)
}

if(!require(reshape2)){
  install.packages("reshape2",repos = "https://mirrors.ebi.ac.uk/CRAN/")
  library(reshape2)
}

if(!require(cowplot)){
  install.packages("cowplot",repos = "https://mirrors.ebi.ac.uk/CRAN/")
  library(cowplot)
}


## Mapping the exons onto the plot in plot 2
## Read in bed file used to calculate DepthofCoverage in GATK
bed.regions <- read.table("pkm_coverage/ExonsSpreadsheet-Homo_sapiens_Transcript_Exons_ENST00000285071.txt")
## Grep regions that correspond to exons and not introns - if BED4 was used
bed.regions.exons <- bed.regions[grepl("Exon",bed.regions$V4),]
## 1-base coordinate systems cause a loss of the required base in the index file / -1 resolves matching the bed to the indexed target
bed.regions.exons$V2 <- bed.regions.exons$V2 - 1
## Add column for the number of each exon
bed.regions.exons$V4 <- gsub("Exon","",bed.regions.exons$V4)
## Convert BED start and stop into matching target format
bed.regions.exons$START <- paste(bed.regions.exons$V1,":",bed.regions.exons$V2,sep="")
bed.regions.exons$STOP <- paste(bed.regions.exons$V1,":",bed.regions.exons$V3,sep="")

place_holder <- data.frame(IDX=seq.int(1,max(bed.regions$V3)-min(bed.regions$V2)+1,by = 1),Locus=paste("chr17:",seq.int(min(bed.regions$V2),max(bed.regions$V3),by = 1),sep = ""))
breaks <- seq.int(2500,max(place_holder$IDX),5000)
x.labs <- gsub("chr17:","",unique(as.character(place_holder$Locus[place_holder$IDX %in% breaks])))

# Find the matching index numbers for each target position coresponding to the start and stop of each exon
bed.regions.exons$START <- sort(unique(place_holder$IDX[place_holder$Locus %in% bed.regions.exons$START]))
bed.regions.exons$STOP <- sort(unique(place_holder$IDX[place_holder$Locus %in% bed.regions.exons$STOP]))

## Plot 2 - visualistion of the target region exons:
## geom_rect plots the exon features / geom_hline adds a joining line / geom_text adds exon numbers
ggplot(bed.regions.exons) + 
  geom_hline(yintercept = 0.5,color="grey20") +
  geom_rect(aes(xmin = START,xmax = STOP, ymin = 0, ymax = 1),fill="grey50",color="grey20",size=0.25) + 
  geom_text(y = 1.3, x = (bed.regions.exons$STOP+bed.regions.exons$START) / 2, label=bed.regions.exons$V4, size = 2) +
  ## Theme modifications for altering plot appearance
  theme(axis.line.x = element_line(),axis.ticks.y = element_blank(),axis.text.y = element_blank()) + 
  theme(panel.background = element_blank(),panel.grid.major.y = element_blank(),axis.text.x = element_text(size = 6)) +
  theme(axis.title.y = element_text(size = 6),plot.caption = element_text(size=4,color="grey20",face = "italic")) +
  theme(panel.grid.major.x = element_line(colour = "grey90",size = .1)) +
  ## Plot titles and labels
  labs(y = "Exons",caption="FLCN") +
  ## Modified parameters for plot scaling and colouration
  scale_x_continuous(breaks = breaks,labels = x.labs,limits = c(1,max(place_holder$IDX))) +
  scale_y_continuous(expand = c(0,0),limits = c(-0.5,1.5)) +
  theme(aspect.ratio = 0.1)
