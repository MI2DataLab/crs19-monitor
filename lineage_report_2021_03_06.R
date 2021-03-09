############
## load packages
library(ggplot2)
library(Cairo)
library(grid)
library(dplyr)
library(ggrepel)
library(lubridate)
library(pammtools)
library(forcats)

############
## read data
lineage_date <- "2021/03/09"
lineage_report <- "dane/lineage_report_2021_03_09.csv"
nextclade_report <- "dane/nextclade-19_2021_03_09.tsv"

lineage <- read.table(lineage_report, sep = ",", header = TRUE)
nextclade <- read.table(nextclade_report, sep = "\t", header = TRUE)

############
## preprocess data

lineage$date <- sapply(strsplit(lineage$Sequence.name, split = "|", fixed = TRUE),
                       function(x) substr(paste0(tail(x, 1), "-01"), 1, 10))

lineage$sample <- gsub(sapply(strsplit(lineage$Sequence.name, split = "\\|"), `[`, 2), pattern = " ", replacement = "")

lineage$lineage_small <- fct_infreq(lineage$Lineage)
lineage$lineage_small <- fct_lump(lineage$lineage_small, n = 8, other_level = "Inne")


# -------
# Liczba na tydzień

pl_seq_1 <- ggplot(lineage, aes(ymd(date))) +
  geom_histogram(binwidth = 7, color = "white") +
  theme_minimal() +
  scale_x_date("", date_breaks = "2 months", date_labels = "%m") +
  scale_y_continuous("", expand = c(0,0)) +
  ggtitle("Nowych sekwencji na tydzień")

# ---------------

t_cou_lin <- table(lineage$date)
df <- as.data.frame(t_cou_lin)

pl_seq_2 <- ggplot(df, aes(ymd(Var1), y = cumsum(Freq))) +
  geom_step() + geom_hline(yintercept = 0) +
  theme_minimal() +
  scale_x_date("", date_breaks = "2 months", date_labels = "%m") +
  scale_y_continuous("", expand = c(0,0)) +
  ggtitle("Łącznie zebranych sekwencji")


# -------
# Ewolucja wariantów

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

pl_war_1 <- ggplot(df3, aes(ymd(date), ymax=n, ymin=0, fill = variant == "B.1.1.7")) +
  geom_stepribbon() +
  geom_text(data = counts, aes(x = ymd(date), y = n, label = label, hjust = 0, vjust = 1), size=3) +
  scale_fill_manual(values = c("blue4", "red4")) +
  scale_x_date("", date_breaks = "1 month", date_labels = "%m",
               limits = c(ymd(lineage_date) - months(3), ymd(lineage_date))) +
#  scale_x_date("", date_breaks = "2 months", date_labels = "%m") +
  facet_wrap(~variant, ncol = 5) +
  theme_minimal() + scale_y_continuous("", expand = c(0,0)) +
  ggtitle("Liczba sekwencji wariantów wirusa (ostatnie 3 miesiące)") +
  theme(legend.position = "none")

# ----------

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

pl_war_2 <- ggplot(df3, aes(ymd(date), y=n, color = variant == "B.1.1.7", group = variant)) +
  geom_step() +
  geom_step(data = df3[df3$variant == "B.1.1.7",], size=1.1) +
  geom_text_repel(data = counts[counts$variant == "B.1.1.7",], aes(x = ymd(lineage_date), y = label, label = variant, hjust = 0, vjust = 1), size=3, direction = "y") +
  scale_color_manual(values = c("grey", "red3")) +
  scale_x_date("", date_breaks = "2 weeks", date_labels = "%m/%d",
               limits = c(ymd(lineage_date) - months(6), ymd(lineage_date))) +
  theme_minimal() + scale_y_continuous("", expand = c(0,0)) +
  ggtitle("Liczba sekwencji wariantów wirusa (ostatnie 6 miesięcy)") +
  theme(legend.position = "none")


############
## update HTML file

html <- paste(readLines("docs/index_source.html"), collapse = "\n")

html <- gsub(pattern = "--DATE--", replacement = lineage_date, x = html)
html <- gsub(pattern = "--NUMBER--", replacement = nrow(lineage), x = html)
html <- gsub(pattern = "--VARIANTS--", replacement = length(unique(lineage$Lineage)), x = html)
html <- gsub(pattern = "--DATELAST--", replacement = max(lineage$date), x = html)


t_cou_lin <- table(lineage$date, lineage$lineage_small)

warianty <- colnames(t_cou_lin)[-ncol(t_cou_lin)]
warianty_list <- paste0(paste0('<a href="https://cov-lineages.org/lineages/lineage_',warianty,'.html">',warianty,'</a>'), collapse = ",\n")
html <- gsub(pattern = "--VARIANTSLIST--", replacement = warianty_list, x = html)

writeLines(html, con = "docs/index.html")


############
## save plots

ggsave(plot = pl_seq_1, file="docs/images/liczba_seq_1.svg", width=4, height=2.5)

ggsave(plot = pl_seq_2, file="docs/images/liczba_seq_2.svg", width=4, height=2.5)

ggsave(plot = pl_war_1, file="docs/images/liczba_warianty_1.svg", width=8, height=3)

ggsave(plot = pl_war_2, file="docs/images/liczba_warianty_2.svg", width=8, height=3)
