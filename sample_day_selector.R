## Custome test dataframe - 4 samples - example day values - randomised result vals - NA measurement col 
df <- data.frame(Sample=c(rep("SAMP1",8),rep("SAMP2",8),rep("SAMP3",8),rep("SAMP4",8)),
                 Day=c(-15,0,29,58,87,120,160,220,-12,0,20,59,85,110,170,200,-13,0,27,62,85,127,162,201,-12,0,30,56,91,130,175,215),
                 Result=c(rnorm(16,10,3)),
                 Measurement=rep(NA,16))

## Assignment of timepoints and distance variables
timepoints <- c(0,30,60,90,120)
distance <- 5

## assign empty vector to d
d <- vector()
# for each sample in df
for(s in unique(df$Sample)){
  ## assign empty vector to p -> select only sample 's'
  p <- vector()
  df.s <- df[df$Sample == s,]
  ## for each timepoint -> find closest value & add to p
  for(i in timepoints){
    p <- append(p,which.min(abs(df.s$Day-i)))
  }
  ## Test values of p for distance from timepoints -> return index of TRUE values in p
  p.match <- which(df.s$Day[p] - timepoints < distance & df.s$Day[p] - timepoints > -(distance))
  ## add measurement vector col of sample -> NA values replaced by index of TRUE values in p at position p
  d <- append(d,replace(df.s$Measurement,p[p.match],values = p.match))
}
## replace measurement col in df with new col d
df$Measurement <- d
