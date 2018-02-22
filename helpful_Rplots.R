library(ggplot2)
library(reshape2)
library(RColorBrewer)

df <- data.frame(replicate(100,rnorm(26,500,50)))
df$sample <- letters
rownames(df) <- letters
colnames(df) <- seq.int(1,ncol(df),1)

## LABELLED PCA
pca <- prcomp(df[1:100])
pca_data <- pca$x

## Random colours
colors1 <- sample(colours(),size = 26)
## Colours by plot value
colors2 <- ifelse(pca_data[,1] > -100 & pca_data[,2] > 10,"red","black")

plot(pca$x[,1],pca$x[,2],pch = 20, col = colors2)


## melting and casting a dataframe

m.df <- melt(df)
colnames(m.df) <- c("sample","day","value")
#dcast(m.df,sample ~ day,value.var = "value")

## A matrix heatmap
cols <- colorRampPalette(c("green","white","red"))(1000)
heatmap(as.matrix(df[-ncol(df)]),Colv = NA,col = cols)

## A basic line plot with highlighted value
ggplot(m.df) +
  geom_line(data = m.df[!m.df$sample == "a",], aes(x=day,y=value,group=sample), colour = alpha("black",0.1)) +
  geom_line(data = m.df[m.df$sample == "a",], aes(x=day,y=value,group=sample), colour = alpha("red",1)) +
  theme(panel.background = element_rect(fill="white"))
