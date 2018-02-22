TsTv.qual <- read.table("RCC_noQC.TsTv.qual", sep = "\t", header = TRUE)
q <- seq(10,100, by=1)

TsTv.filtered <- TsTv.qual[TsTv.qual$QUAL_THRESHOLD %in% q,]
TsTv.filtered <- TsTv.filtered[c(1,7)]

p1 <- ggplot(TsTv.filtered, aes(x = QUAL_THRESHOLD, y = Ts.Tv_GT_QUAL_THRESHOLD)) +
geom_smooth(colour = "steelblue3") +
geom_hline(yintercept= 2.2, linetype = "dashed", size=1) +
geom_hline(yintercept= 3.0, linetype = "dashed", size=1) +
labs(list(title = "Transition/Transversion Ratio against Site Quality", y = "TsTv Ratio", x = "QUAL")) +
theme(panel.border = element_blank(), axis.line = element_line(colour="black"), panel.grid.major = element_line(colour = "gray90"), plot.margin= unit(c(0.5,1,0.5,0.5), "cm")) +
theme(panel.grid.minor = element_blank(),panel.background=element_blank(), plot.title = element_text(size = 14,colour = "gray10",margin = margin(0,0,10,0))) +
scale_x_continuous(expand = c(0,0), breaks=seq(10,100,by=10)) +
scale_y_continuous(expand = c(0,0), limits = c(1.8,3.1), breaks=seq(1.8,3.0,by=0.2)) +
annotate("text", label = "Ideal TsTv - WGS", x = 80, y = 2.16, size = 4, colour = "#115E67") +
annotate("text", label = "Ideal TsTv - WES", x = 80, y = 2.96, size = 4, colour = "#115E67")

png(p1, file = "tstv_QUAL.png", width=4, length=4, unit="in", res=300)
p1
dev.off()
