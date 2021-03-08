library(ggplot2)
library(Cairo)
library(grid)
library(dplyr)
library(lubridate)
library(pammtools)
library(forcats)

# data reports
lineage_report <- "dane/lineage_report_2021_03_06.csv"
lineage_date <- "2021/03/06"



# read data
lineage <- read.table(lineage_report, sep = ",", header = TRUE)
lineage$date <- sapply(strsplit(lineage$Sequence.name, split = "|", fixed = TRUE), 
                       function(x) substr(paste0(tail(x, 1), "-01"), 1, 10))


lineage$sample <- gsub(sapply(strsplit(lineage$Sequence.name, split = "\\|"), `[`, 2), pattern = " ", replacement = "")

library(Cairo)

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



# read html

html <- paste(readLines("docs/index_source.html"), collapse = "\n")

html <- gsub(pattern = "--DATE--", replacement = lineage_date, x = html)
html <- gsub(pattern = "--NUMBER--", replacement = nrow(lineage), x = html)
html <- gsub(pattern = "--VARIANTS--", replacement = length(unique(lineage$Lineage)), x = html)

warianty <- colnames(t_cou_lin)[-ncol(t_cou_lin)]
warianty_list <- paste0(paste0('<a href="https://cov-lineages.org/lineages/lineage_',warianty,'.html">',warianty,'</a>'), collapse = ",\n")
html <- gsub(pattern = "--VARIANTSLIST--", replacement = warianty_list, x = html)




writeLines(html, con = "docs/index.html")



# -------
# Ewolucja wariantów

lineage$lineage_small <- fct_infreq(lineage$Lineage)
lineage$lineage_small <- fct_lump(lineage$lineage_small, n = 8, other_level = "Inne")

t_cou_lin <- table(lineage$date, lineage$lineage_small)
t_cou_lin <- apply(t_cou_lin, 2, cumsum)

df3 <- as.data.frame(as.table(t_cou_lin))
colnames(df3) <- c("date", "variant", "n")

counts <- data.frame(variant = factor(names(t_cou_lin[nrow(t_cou_lin),]), 
                                      labels = names(t_cou_lin[nrow(t_cou_lin),]),
                                      levels = names(t_cou_lin[nrow(t_cou_lin),])),
                     label = t_cou_lin[nrow(t_cou_lin),],
                     date = "2020/03/01",
                     n = max(t_cou_lin[nrow(t_cou_lin),]))

pl3 <- ggplot(df3, aes(ymd(date), ymax=n, ymin=0, fill = variant == "B.1.1.7")) +
  geom_stepribbon() + 
  geom_text(data = counts, aes(x = ymd(date), y = n, label = label, hjust = 0, vjust = 1), size=3) + 
  scale_fill_manual(values = c("blue4", "red4")) +
  scale_x_date("", date_breaks = "2 months", date_labels = "%m") + 
  facet_wrap(~variant, ncol = 5) + 
  theme_minimal() + scale_y_continuous("", expand = c(0,0)) +
  ggtitle("Liczba sekwencji wariantów wirusa") +
  theme(legend.position = "none")

ggsave(plot = pl3, file="docs/images/liczba_warianty_1.svg", width=8, height=3)




lineage$lineage_small <- fct_infreq(lineage$Lineage)
lineage$lineage_small <- fct_lump(lineage$lineage_small, n = 30, other_level = "Inne")
t_cou_lin <- table(lineage$date, lineage$lineage_small)
t_cou_lin <- apply(t_cou_lin, 2, cumsum)
df3 <- as.data.frame(as.table(t_cou_lin))
colnames(df3) <- c("date", "variant", "n")

counts <- data.frame(variant = factor(names(t_cou_lin[nrow(t_cou_lin),]), 
                                      labels = names(t_cou_lin[nrow(t_cou_lin),]),
                                      levels = names(t_cou_lin[nrow(t_cou_lin),])),
                     label = t_cou_lin[nrow(t_cou_lin),],
                     date = "2020/03/01",
                     n = max(t_cou_lin[nrow(t_cou_lin),]))

pl4 <- ggplot(df3, aes(ymd(date), y=n, color = variant == "B.1.1.7", group = variant)) +
  geom_step() + 
  geom_text(data = counts, aes(x = ymd(lineage_date), y = label, label = variant, hjust = 0, vjust = 1), size=3) + 
  scale_color_manual(values = c("blue4", "red3")) +
  scale_x_date("", date_breaks = "2 months", date_labels = "%m") + 
  theme_minimal() + scale_y_continuous("", expand = c(0,0)) +
  ggtitle("Liczba sekwencji wariantów wirusa") +
  theme(legend.position = "none")

ggsave(plot = pl4, file="docs/images/liczba_warianty_2.svg", width=8, height=3)


