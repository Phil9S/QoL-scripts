## Pretty dendrogram with group leaves
## Hclust dendrogram plot

#Uses packages:
#   - ggplot2
#   - ggdendro
#   - RColorBrewer

plot_pretty_hclust <- function(data=NULL,sample=NULL,group=NULL,clustMethod="complete",assaydata="segments"){
    if(!require(RColorBrewer)){
        stop("requires RColorBrewer")
    }
    if(!require(ggplot2)){
        stop("requires ggplot2")
    }
    if(!require(ggdendro)){
        stop("requires ggdendro")
    }
    bin.hclust <- hclust(dist(t(data)))
    dendro.dat <- as.dendrogram(bin.hclust)
    dd.dat <- dendro_data(dendro.dat)
    
    colors.table <- data.frame(groups=levels(as.factor(group)),
                               color=brewer.pal(n = length(levels(as.factor(group))),
                                                name = 'Paired'))
    
    colors <- as.vector(colors.table$color[match(group[bin.hclust$order],colors.table$groups)])
    names(colors) <- colors.table$groups[match(group[bin.hclust$order],colors.table$groups)]
    
    p <- ggplot(ggdendro::segment(dd.dat)) +
        geom_segment(aes(x = x, y = y, xend = xend, yend = yend)) +
        geom_point(data = ggdendro::label(dd.dat),
                   aes(x = x,
                       y = -50),
                   size = 4, color = "black") +
        geom_point(data = ggdendro::label(dd.dat),
                   aes(x = x,
                       y = -50,
                       color = names(colors)),
                   size = 2.5 ) +
        geom_text(data = ggdendro::label(dd.dat),
                  aes(label = label,x = x, y = y),
                  angle=90,
                  nudge_y = -100,
                  hjust = 1) +
        scale_color_manual(name="group",values = colors[!duplicated(colors)],guide = guide_legend(nrow = 1)) +
        #scale_y_continuous(limits = c(-500,NA)) +
        theme(plot.background = element_blank(),
              axis.text = element_blank(),
              axis.ticks = element_blank(),
              axis.title = element_blank(),
              panel.background = element_blank(),
              legend.background = element_blank(),
              legend.position = "bottom",legend.justification = "center",
              legend.key = element_blank())
    return(p)
}

## Generate random data.set with 10 samples and 3 groups
samples <- c(LETTERS[1:10])
groups <- c(rep("A",times=2),rep("B",times=5),rep("C",times=3))
test.data <- matrix(c(rnorm(n = 20,mean = 300),
                      rnorm(n = 50,mean = 12),
                      rnorm(n = 30,mean = 1)),
                    nrow = 10,ncol = 10)
## Plot dendro
plot_pretty_hclust(data = test.data,sample = samples,group = groups)
