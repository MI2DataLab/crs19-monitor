library(ggplot2)
library(Cairo)
library(grid)
library(dplyr)
library(lubridate)
library(pammtools)
library(forcats)

lineage <- read.table("dane/lineage_report_2021_02_28.csv", sep = ",", header = TRUE)
lineage$date <- sapply(strsplit(lineage$taxon, split = "|", fixed = TRUE), 
                       function(x) substr(paste0(tail(x, 1), "-01"), 1, 10))

# http://penelope.unito.it/sars-cov-2_detection/Poland.html
lines <- readLines("dane/Poland_2021_02_28.txt")


sapply(strsplit(grep(lines, pattern = "^.*EPI", value = TRUE), split ="\t"), 
       `[`, 2) -> location
sapply(strsplit(grep(lines, pattern = "^.*EPI", value = TRUE), split ="\t"), 
       `[`, 1) -> sample
df <- data.frame(sample, location)

df$location <- c("dolnoslakie" = "Dolnośląskie", "dolnoslaskie" = "Dolnośląskie", "dolnośląskie" = "Dolnośląskie", 
  "iodzkie" = "Łódzkie", 
  "lodzkie" = "Łódzkie", "łódzkie" = "Łódzkie", "lubuskie" = "Lubuskie", 
  "malopolska" = "Malopolskie", "malopolskie" = "Malopolskie", 
  "masovia" = "Mazowieckie", "mazowieckie" = "Mazowieckie", 
  "opolskie" = "Opolskie", "podkarpackie" = "Podkarpackie", 
  "pomerania" = "Pomorskie", 
  "pomorskie" = "Pomorskie", "pomorze" = "Pomorskie", "slask" = "Śląskie", "slaskie" = "Śląskie", 
  "swietokrzyskie" = "Świetokrzyskie", 
  "warminsko-mazurskie" = "Warminsko-mazurskie", 
  "wielkopolska" = "Wielkopolskie", "wielkopolskie" = "Wielkopolskie", 
  "zachodniopomorskie" = "Zachodniopomorskie", 
  "zielonogorskie" = "Zielonogorskie")[tolower(df$location)] 

lineage$sample <- gsub(sapply(strsplit(lineage$taxon, split = "\\|"), `[`, 2), pattern = " ", replacement = "")
df$sample <- gsub(df$sample, pattern = " ", replacement = "")

dfl <- merge(df, lineage[,c("lineage", "sample")], by.x = "sample", by.y = "sample")
dfl$location <- fct_infreq(dfl$location)
dfl$lineage <- fct_infreq(dfl$lineage)
dfl$lineage <- fct_lump(dfl$lineage, 8, other_level = "Inne")
dfl$location <- fct_lump(dfl$location, 8, other_level = "Inne")
table(dfl$location, dfl$lineage)

library(Cairo)
svg("docs/images/liczba_rejon_1.svg", 7, 4)
par(mar = c(0,0,0,0))
mosaicplot(table(dfl$location, dfl$lineage)[9:1,], off = c(0,0), border = "white", 
           dir = c("h", "v"), las = 2, color = RColorBrewer::brewer.pal(10, "Paired"),
           main = "")
dev.off()

library(ca)
tab <- table(dfl$location, dfl$lineage, useNA = "ifany")
ca(tab)

svg("docs/images/liczba_rejon_2.svg", 5, 5)
par(mar = c(0,0,0,0))
plot(ca(tab), arrows = c(FALSE, TRUE))
dev.off()


# library(rgdal)
# library(rgeos)
# library(tidyverse)
# library(broom) # for tidy=fortify
# 
# wojewodztwa <- readOGR("dane/wojewodztwa/wojewodztwa.shp", "wojewodztwa")
# 
# wojewodztwa <- spTransform(wojewodztwa, CRS("+init=epsg:4326"))
# 
# ggplot(wojewodztwa) +
#   geom_polygon(aes(long, lat, group=group, fill=group), color="gray", show.legend = FALSE) +
#   coord_map() +
#   theme_void()



# -------
# Liczba na tydzień

pl <- ggplot(lineage, aes(ymd(date))) + 
  geom_histogram(binwidth = 7, color = "white") + 
  theme_minimal() + 
  scale_x_date("", date_breaks = "2 months", date_labels = "%m") + 
  scale_y_continuous("", expand = c(0,0)) +
  ggtitle("Nowych sekwencji na tydzień")

ggsave(plot = pl, file="docs/images/liczba_seq_1.svg", width=4, height=2.5)

t_cou_lin <- table(lineage$date)
df <- as.data.frame(t_cou_lin)

pl <- ggplot(df, aes(ymd(Var1), y = cumsum(Freq))) + 
  geom_step() + geom_hline(yintercept = 0) +
  theme_minimal() + 
  scale_x_date("", date_breaks = "2 months", date_labels = "%m") + 
  scale_y_continuous("", expand = c(0,0)) +
  ggtitle("Łącznie zebranych sekwencji")

ggsave(plot = pl, file="docs/images/liczba_seq_2.svg", width=4, height=2.5)

# -------
# Ewolucja wariantów

lineage$lineage_small <- fct_infreq(lineage$lineage)
lineage$lineage_small <- fct_lump(lineage$lineage_small, n = 8, other_level = "Inne")

t_cou_lin <- table(lineage$date, lineage$lineage_small)
t_cou_lin <- apply(t_cou_lin, 2, cumsum)

df3 <- as.data.frame(as.table(t_cou_lin))
colnames(df3) <- c("date", "variant", "n")

pl3 <- ggplot(df3, aes(ymd(date), ymax=n, ymin=0, fill = variant == "B.1.1.7")) +
  geom_stepribbon() + 
  scale_fill_manual(values = c("blue4", "red4")) +
  scale_x_date("", date_breaks = "2 months", date_labels = "%m") + 
  facet_wrap(~variant, ncol = 5) + 
  theme_minimal() + scale_y_continuous("", expand = c(0,0)) +
  ggtitle("Liczba sekwencji wariantów wirusa") +
  theme(legend.position = "none")

ggsave(plot = pl3, file="docs/images/liczba_warianty_1.svg", width=8, height=3)

# -------
# Nazwy wariantów

warianty <- colnames(t_cou_lin)
cat(paste0(paste0('<a href="https://cov-lineages.org/lineages/lineage_',warianty,'.html">',warianty,'</a>,'), collapse = "\n") )

# -------
# Drzewo wariantów

w_names <- unique(lineage$lineage)
mat <- matrix(0, length(w_names), length(w_names))

for (i in 1:length(w_names)) {
  for (j in 1:length(w_names)) {
    a <- paste(w_names[i], runif(1)*1000, runif(1)*1000, sep= ".")
    b <- paste(w_names[j], runif(1)*1000, runif(1)*1000, sep= ".")
    tmp <- strsplit(c(a, b), "\\.")
    mat[i,j] <- mean(head(tmp[[1]], 5) != head(tmp[[2]], 5))
  }
}
rownames(mat) <- w_names
colnames(mat) <- w_names

library("ggtree")
require("ape") 
hc <- hclust(as.dist(mat))
plot(hclust(as.dist(mat)), horiz=TRUE)

plot(as.phylo(hc), type = "unrooted", cex = 0.6)

phy1 <- nj(mat)
phy1 <- njs(mat)
phy1
ggtree(phy1, branch.length="none")
ggtree(phy1, branch.length="none", layout="circular") + geom_tiplab()


table(lineage$lineage)

t_cou_lin <- table(lineage$date, lineage$lineage)
t_cou_lin <- apply(t_cou_lin, 2, cumsum)

H <- apply(t_cou_lin, 1, function(x) {
  probs <- x/sum(x)
  probs <- probs[probs > 0]
  sum(-probs*log(probs))
})

N <- apply(t_cou_lin, 1, function(x) {
  sum(x)
})

library(ggrepel)
library(lubridate)
df <- data.frame(cnt = names(H), H = H, N = N, date = ymd(names(H)))
r1 <- ggplot(df[N>2,], aes(date, H, label = cnt)) + 
  geom_step() + 
  theme_light() + xlab("") + ylab("H entropy") +
  ggtitle("GISAID: entropy of variants in Poland")

r2 <- ggplot(lineage, aes(ymd(date))) + 
  geom_histogram(bins = 100) + 
  theme_light() + xlab("") + ylab("ncases") +
  ggtitle("GISAID: number of sequences Poland")

library(patchwork)
r1 / r2 +
  plot_layout(heights = c(2,1))



