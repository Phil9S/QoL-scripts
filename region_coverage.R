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

## Load target.coverage data from per base depth of coverage information output by GATK DepthofCoverage
c1958.targets <- read.table("1958.targets.coverage",sep = "\t",header = TRUE,quote = "",comment.char = "")
## Add an index col to plot against / Drop unused columns / Save sample column names to vector
c1958.targets <- cbind(IDX=seq.int(1,nrow(c1958.targets),1),c1958.targets)
c1958.targets <- c1958.targets[-c(3,4)]
cols.1958 <- colnames(c1958.targets[3:ncol(c1958.targets)])

## Load target.coverage data from per base depth of coverage information output by GATK DepthofCoverage
rcc.targets <- read.table("rcc.targets.coverage",sep = "\t",header = TRUE,quote = "",comment.char = "")
## Add an index col to plot against / Drop unused columns
rcc.targets <- cbind(IDX=seq.int(1,nrow(rcc.targets),1),rcc.targets)
rcc.targets <- rcc.targets[-c(3,4)]

## Optional filtering based on number of samples in depthofcoverage output - limit to reduce compute time
#rcc.targets <- rcc.targets[c(1:10,ncol(rcc.targets))]
c1958.targets <- c1958.targets[c(1:131,ncol(c1958.targets))]

## Merge two datasets being compared on the targets - data shold be against the same bed file therefore same targets
targets <- merge(c1958.targets,rcc.targets, by = c("IDX","Locus"),all = TRUE)
## Melt targets files into ggplot2 format for ploting
melt.targets <- melt(targets,id.vars = c("IDX","Locus"),variable.name = "sample")
## Add groupings based on if the col names are in the saved list during data entry
melt.targets$GROUP <- factor(ifelse(melt.targets$sample %in% cols.1958,"1958","RCC"))

## Additional information to add annotation for mutations of interest - Add by finding corresponding index value
mut <- unique(melt.targets$IDX[melt.targets$Locus == "chr15:72230974"])

## Defining axis breaks and labels based on index values and target look up
breaks <- c(5000,15000,25000,32000)
x.labs <- gsub("chr15:","",unique(as.character(melt.targets$Locus[melt.targets$IDX %in% breaks])))

## Plot 1 - Depth over each target base - Geom_line split on $GROUP (i.e case or control)
p <- ggplot(melt.targets) +
      geom_line(aes(IDX,value,color=GROUP),alpha=0.6) +
  ## Theme modifications for altering plot appearance
      theme(axis.line.x = element_line(),axis.line.y = element_line(),axis.ticks.y = element_blank()) +
      theme(legend.position = c(0.01, 0.99),legend.justification = c("left", "top"),legend.direction = "horizontal") + 
      theme(panel.background = element_blank(),panel.grid.major = element_line(colour = "grey90",size = .1)) +
      theme(axis.title.x = element_blank(),axis.ticks.x = element_blank(),axis.text.x = element_blank(),legend.text = element_text(size = 4)) +
      theme(axis.text.y = element_text(size = 4),axis.title.y = element_text(size = 6),legend.title = element_blank(),legend.key.size = ) +
      theme(legend.margin = margin(t = 0, unit='cm'),plot.margin = margin(5,5,0,5,"pt"),plot.title = element_text(size = 8,hjust = 0)) +
  ## Plot titles and labels
      labs(title = "PKM exome coverage - 1958 vs RCC",y = "Read depth") +
  ## Modified parameters for plot scaling and colouration
      scale_x_continuous(expand = c(0,0),breaks = breaks,labels = x.labs) +
      scale_y_continuous(expand = c(0,0),limits = c(0,max(melt.targets$value)+50),breaks = c(30,100,500)) +
      scale_colour_manual(values = c("#e6ab02","#7570b3"))

## Additional annotation layers for plot 1 - Mutation of interest / location line / modifying legend label size
p <- p + annotate("segment", x = mut,xend = mut,y = 0, yend = max(melt.targets$value)+50,colour = "grey20",linetype=2,size=0.15) +
         annotate("text",label="PKM Trunc.",x = mut-1250,y = max(melt.targets$value)+25, size=1.5,color="grey20") +
         guides(colour = guide_legend(override.aes = list(size=1)))

## Mapping the exons onto the plot in plot 2
## Read in bed file used to calculate DepthofCoverage in GATK
bed.regions <- read.table("PKM_ENST00000319622.sorted.bed")
## Grep regions that correspond to exons and not introns - if BED4 was used
bed.regions.exons <- bed.regions[grepl("Exon",bed.regions$V4),]
## 1-base coordinate systems cause a loss of the required base in the index file / -1 resolves matching the bed to the indexed target
bed.regions.exons$V2 <- bed.regions.exons$V2 - 1
## Add column for the number of each exon
bed.regions.exons$V4 <- gsub("Exon","",bed.regions.exons$V4)
## Convert BED start and stop into matching target format
bed.regions.exons$START <- paste(bed.regions.exons$V1,":",bed.regions.exons$V2,sep="")
bed.regions.exons$STOP <- paste(bed.regions.exons$V1,":",bed.regions.exons$V3,sep="")
## Find the matching index numbers for each target position coresponding to the start and stop of each exon
bed.regions.exons$START <- sort(unique(melt.targets$IDX[melt.targets$Locus %in% bed.regions.exons$START]))
bed.regions.exons$STOP <- sort(unique(melt.targets$IDX[melt.targets$Locus %in% bed.regions.exons$STOP]))

## Plot 2 - visualistion of the target region exons:
## geom_rect plots the exon features / geom_hline adds a joining line / geom_text adds exon numbers
e <- ggplot(bed.regions.exons) + 
      geom_hline(yintercept = 0.5,color="grey20") +
      geom_rect(aes(xmin = START,xmax = STOP, ymin = 0, ymax = 1),fill="grey50",color="grey20",size=0.25) + 
      geom_text(y = 1.3, x = (bed.regions.exons$STOP+bed.regions.exons$START) / 2, label=bed.regions.exons$V4, size = 1.5) +
  ## Theme modifications for altering plot appearance
      theme(axis.line.x = element_line(),axis.ticks.y = element_blank(),axis.text.y = element_blank()) + 
      theme(panel.background = element_blank(),panel.grid.major.y = element_blank(),axis.text.x = element_text(size = 4)) +
      theme(axis.title.y = element_text(size = 6),plot.caption = element_text(size=4,color="grey20",face = "italic")) +
      theme(panel.grid.major.x = element_line(colour = "grey90",size = .1)) +
  ## Plot titles and labels
      labs(y = "Exons",caption="chr15:72197029-72231585") +
  ## Modified parameters for plot scaling and colouration
      scale_x_continuous(expand = c(0,0),breaks = breaks,labels = x.labs,limits = c(1,max(melt.targets$IDX))) +
      scale_y_continuous(expand = c(0,0),limits = c(-0.5,1.5))

## Output plot to .png format at 600dpi
png("region_coverage.png",width = 6,height = 3,units = "in",res = 600)
## Plot grid aligns and merges both plots into a single plot - rel-heights indicates the ratio between plot 1 and plot 2
plot_grid(p,e,nrow = 2,rel_heights = c(0.7,0.3),align = 'v')
dev.off()

