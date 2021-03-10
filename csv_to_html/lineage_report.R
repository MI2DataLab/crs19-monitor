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

theme_set(theme_gray(base_family = 'Arial' ))

############
## read data
lineage_date <- Sys.getenv("LINEAGE_DATE")
lineage_report <- Sys.getenv("LINEAGE_REPORT_PATH")
nextclade_report <- Sys.getenv("NEXTCLADE_REPORT_PATH")
metadata_report <- Sys.getenv("METADATA_REPORT_PATH")
output_dir <- Sys.getenv("OUTPUT_PATH")

lineage <- read.table(lineage_report, sep = ",", header = TRUE)
nextclade <- read.table(nextclade_report, sep = "\t", header = TRUE)
metadata <- read.table(metadata_report, sep = ",", header = TRUE)

############
## preprocess data
lineage$date <- sapply(strsplit(lineage$Sequence.name, split = "|", fixed = TRUE),
                       function(x) substr(paste0(tail(x, 1), "-01"), 1, 10))

lineage$sample <- gsub(sapply(strsplit(lineage$Sequence.name, split = "\\|"), `[`, 2), pattern = " ", replacement = "")

lineage$lineage_small <- fct_infreq(lineage$Lineage)
lineage$lineage_small <- fct_other(lineage$lineage_small,
                                   keep = unique(c(head(levels(lineage$lineage_small), 7), "B.1.1.7", "B.1.351")), other_level = "Inne")
#lineage$lineage_small <- fct_lump(lineage$lineage_small, n = 8, other_level = "Inne")


nextclade$date <- sapply(strsplit(nextclade$seqName, split = "|", fixed = TRUE),
                       function(x) substr(paste0(tail(x, 1), "-01"), 1, 10))
nextclade$sample <- gsub(sapply(strsplit(nextclade$seqName, split = "\\|"), `[`, 2), pattern = " ", replacement = "")
nextclade$clade_small <- fct_infreq(nextclade$clade)
nextclade$clade_small <- fct_lump(nextclade$clade_small, n = 12, other_level = "Inne")


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
                     date = "2020/12/15",
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
  ggtitle("Liczba sekwencji wariantów wirusa (Pango, ostatnie 3 miesiące)") +
  theme(legend.position = "none")

# -------
# Ewolucja clades

t_cou_cla <- table(nextclade$date, nextclade$clade_small)
t_cou_cla <- apply(t_cou_cla, 2, cumsum)

df4 <- as.data.frame(as.table(t_cou_cla))
colnames(df4) <- c("date", "variant", "n")

counts4 <- data.frame(variant = factor(names(t_cou_cla[nrow(t_cou_cla),]),
                                      labels = names(t_cou_cla[nrow(t_cou_cla),]),
                                      levels = names(t_cou_cla[nrow(t_cou_cla),])),
                     label = t_cou_cla[nrow(t_cou_cla),],
                     date = "2020/12/15",
                     n = max(t_cou_cla[nrow(t_cou_cla),]))

pl_war_3 <- ggplot(df4, aes(ymd(date), ymax=n, ymin=0, fill = grepl(variant, pattern = "501Y"))) +
  geom_stepribbon() +
  geom_text(data = counts4, aes(x = ymd(date), y = n, label = label, hjust = 0, vjust = 1), size=3) +
  scale_fill_manual(values = c("blue4", "red4")) +
  scale_x_date("", date_breaks = "1 month", date_labels = "%m",
               limits = c(ymd(lineage_date) - months(3), ymd(lineage_date))) +
  #  scale_x_date("", date_breaks = "2 months", date_labels = "%m") +
  facet_wrap(~variant, ncol = 6) +
  theme_minimal() + scale_y_continuous("", expand = c(0,0)) +
  ggtitle("Liczba sekwencji wariantów wirusa (GISAID, ostatnie 3 miesiące)") +
  theme(legend.position = "none")

# ----------

lineage$lineage_small <- fct_infreq(lineage$Lineage)
#lineage$lineage_small <- fct_lump(lineage$lineage_small, n = 30, other_level = "Inne")
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

pl_war_2 <- ggplot(df3, aes(ymd(date), y=n, color = variant %in% c("B.1.1.7","B.1.351"), group = variant)) +
  geom_step() +
  geom_step(data = df3[df3$variant %in% c("B.1.1.7","B.1.351"),], size=1.1) +
  geom_text_repel(data = counts[counts$variant %in% c("B.1.1.7","B.1.351"),], aes(x = ymd(lineage_date), y = label, label = variant, hjust = 0, vjust = 1), size=3, direction = "y") +
  scale_color_manual(values = c("grey", "red3")) +
  scale_x_date("", date_breaks = "2 weeks", date_labels = "%m/%d",
               limits = c(ymd(lineage_date) - months(6), ymd(lineage_date))) +
  theme_minimal() + scale_y_continuous("", expand = c(0,0)) +
  ggtitle("Liczba sekwencji wariantów wirusa (Pango, ostatnie 6 miesięcy)") +
  theme(legend.position = "none")

# ----------

nextclade$clade_small <- fct_infreq(nextclade$clade)
t_cou_cla <- table(nextclade$date, nextclade$clade_small)
t_cou_cla <- apply(t_cou_cla, 2, cumsum)
df5 <- as.data.frame(as.table(t_cou_cla))
colnames(df5) <- c("date", "variant", "n")

counts5 <- data.frame(variant = factor(names(t_cou_cla[nrow(t_cou_cla),]),
                                      labels = names(t_cou_cla[nrow(t_cou_cla),]),
                                      levels = names(t_cou_cla[nrow(t_cou_cla),])),
                     label = t_cou_cla[nrow(t_cou_cla),],
                     date = "2020/03/01",
                     n = max(t_cou_cla[nrow(t_cou_cla),]))

pl_war_4 <- ggplot(df5, aes(ymd(date), y=n, color = variant %in% c("20I/501Y.V1","20H/501Y.V2"), group = variant)) +
  geom_step() +
  geom_step(data = df5[df5$variant %in% c("20I/501Y.V1","20H/501Y.V2"),], size=1.1) +
  geom_text_repel(data = counts5[counts5$variant %in% c("20I/501Y.V1","20H/501Y.V2"),], aes(x = ymd(lineage_date), y = label, label = variant, hjust = 0, vjust = 1), size=3, direction = "y") +
  scale_color_manual(values = c("grey", "red3")) +
  scale_x_date("", date_breaks = "2 weeks", date_labels = "%m/%d",
               limits = c(ymd(lineage_date) - months(6), ymd(lineage_date))) +
  theme_minimal() + scale_y_continuous("", expand = c(0,0)) +
  ggtitle("Liczba sekwencji wariantów wirusa (GISAID, ostatnie 6 miesięcy)") +
  theme(legend.position = "none")

############
## plots from meta data

nextclade$seqName <- gsub(nextclade$seqName, pattern = "\\|.*", replacement = "")
metadata_ext <- merge(metadata, nextclade, by.x = "Virus.name", by.y = "seqName")

pl_war_5 <- ggplot(metadata_ext, aes(ymd(Collection.date), ymd(Submission.Date), color = grepl(clade_small, pattern = "501Y"))) +
  geom_abline(slope = 1, intercept = 0, color = "grey", lty = 4) +
  geom_abline(slope = 1, intercept = 14, color = "grey", lty = 2) +
  geom_abline(slope = 1, intercept = 28, color = "grey", lty = 3) +
  geom_jitter(size = 0.5) +
  ggtitle("", "Przerywane linie - opóźnienie 0, 2 i 4 tygodnie. Czerwone punkty - warianty z mutacją N501Y") +
  theme_bw() + coord_fixed() +
  scale_color_manual("", values = c("blue4", "red2")) +
  scale_x_date("Data pobrania materiału (ostatnie 3 miesiące)", date_breaks = "2 weeks", date_labels = "%m/%d",
               limits = c(ymd(lineage_date) - months(3), ymd(lineage_date)))  +
  scale_y_date("Data zgłoszenia", date_breaks = "2 weeks", date_labels = "%m/%d",
               limits = c(ymd(lineage_date) - months(2), ymd(lineage_date)))+
  theme(legend.position = "none")


############
## update HTML file

html <- paste(readLines(paste0(output_dir, "/index_source.html")), collapse = "\n")

html <- gsub(pattern = "--DATE--", replacement = lineage_date, x = html)
html <- gsub(pattern = "--NUMBER--", replacement = nrow(lineage), x = html)
html <- gsub(pattern = "--DATELAST--", replacement = max(lineage$date), x = html)


t_cou_lin <- table(lineage$date, lineage$lineage_small)

warianty <- head(colnames(t_cou_lin)[-ncol(t_cou_lin)],7)
warianty_list <- paste0(paste0('<a href="https://cov-lineages.org/lineages/lineage_',warianty,'.html">',warianty,'</a>'), collapse = ",\n")
html <- gsub(pattern = "--VARIANTSLIST--", replacement = warianty_list, x = html)
html <- gsub(pattern = "--VARIANTS--", replacement = length(unique(lineage$Lineage)), x = html)

warianty2 <- head(colnames(t_cou_cla),5)
warianty2_list <- paste0(paste0('<a href="https://www.cdc.gov/coronavirus/2019-ncov/more/science-and-research/scientific-brief-emerging-variants.html">',warianty2,'</a>'), collapse = ",\n")
html <- gsub(pattern = "--VARIANTSLIST2--", replacement = warianty2_list, x = html)
html <- gsub(pattern = "--VARIANTS2--", replacement = length(colnames(t_cou_cla)), x = html)

writeLines(html, con = paste0(output_dir, "/index.html"))


############
## save plots

ggsave(plot = pl_seq_1, file=paste0(output_dir, "/images/liczba_seq_1.svg"), width=4, height=2.5)

ggsave(plot = pl_seq_2, file=paste0(output_dir, "/images/liczba_seq_2.svg"), width=4, height=2.5)

ggsave(plot = pl_war_1, file=paste0(output_dir, "/images/liczba_warianty_1.svg"), width=8, height=3)

ggsave(plot = pl_war_2, file=paste0(output_dir, "/images/liczba_warianty_2.svg"), width=8, height=3)

ggsave(plot = pl_war_3, file=paste0(output_dir, "/images/liczba_warianty_3.svg"), width=8, height=3)

ggsave(plot = pl_war_4, file=paste0(output_dir, "/images/liczba_warianty_4.svg"), width=8, height=3)

ggsave(plot = pl_war_5, file=paste0(output_dir, "/images/liczba_warianty_5.svg"), width=8, height=5)
