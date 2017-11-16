fdr <- function(p,q){
  n <- length(p)
  p <- as.numeric(p)
  values <- sort(p,decreasing = FALSE)
  rank <- order(values)
  FDR <- signif(rank/n * q, 5)
  if(sum(values < FDR)){
  adj <- max(which(values < FDR))
  cat(paste("Adjusted significance threshold is: ",values[adj],sep = ""))
  cat("\n")
  } else {
  adj <- 0
  cat(paste("All values insignificant after FDR correction",sep = ""))
  cat("\n")
  }
  significance  <- as.vector(c(rep("TRUE",times=adj),rep("FALSE",times=n-adj)))
  t <- as.data.frame(cbind(rank=rank,pvals=values,q_adj=FDR,signif.=significance),row.names = FALSE)
  return(t)
}
