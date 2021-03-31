############
## load packages
library(ggplot2)
library(Cairo)
library(grid)
library(dplyr)
library(ggrepel)
library(lubridate)
library(forcats)
library(RSQLite)

library(tidyr)
library(rgdal)
library(scatterpie)
library(sf)
library(patchwork)
library(jsonlite)
library(tmaptools)
############
## read data
# lineage_report =  "../../data/pango.csv"
# nextclade_report = "../../data/clades.tsv"
# metadata_report = "../../data/gisaid_metadata.csv"
# lineage_date <- "2021/03/19"
# region <- "Poland"
# db_path <- "../../data/sequences.sqlite"
# output_dir <- "./output/"

lineage_date <- Sys.getenv("LINEAGE_DATE")
#lineage_report <- Sys.getenv("LINEAGE_REPORT_PATH")
#nextclade_report <- Sys.getenv("NEXTCLADE_REPORT_PATH")
output_dir <- Sys.getenv("OUTPUT_PATH")
db_path <- Sys.getenv('DB_PATH')
region <- Sys.getenv('REGION')

print(paste('Region:', region))
con <- dbConnect(RSQLite::SQLite(), db_path)
res <- dbSendQuery(con, 'SELECT * FROM metadata WHERE country = ?')
dbBind(res, list(region))
metadata <- dbFetch(res)
dbClearResult(res)
dbDisconnect(con)

print(paste('Found', nrow(metadata), 'rows in database'))

# Create output dirs
dir.create(paste0(output_dir, '/', 'images'), recursive=TRUE, showWarnings=FALSE)

# Filter by region
lineage <-subset(lineage_full, accession_id %in% metadata$accession_id)
nextclade <-subset(nextclade_full, accession_id %in% metadata$accession_id)
print(paste('Region pango rows:',nrow(lineage)))
print(paste('Region nextclade rows:',nrow(nextclade)))

############
## read titles

langs <- c('pl', 'en')
descriptions <- list()
plots_output <- list()
for (lang in langs) {
	descriptions[[lang]] <- read.table(paste0("lang_", lang, ".txt"), sep=":", header = TRUE, row.names = 1, fileEncoding = "UTF-8", quote=NULL)
	plots_output[[lang]] <- list()
}


# -------
# global variables

DATE_LAST_SAMPLE <- max(ymd(metadata$collection_date), na.rm = T)
ALARM_MUTATION <- "N501Y"
ALARM_PATTERN <- "501Y"
ALARM_PANGO <- c("B.1.1.7", "B.1.351", "P.1")
ALARM_CLADE <- c("20I/501Y.V1","20H/501Y.V2", "20J/501Y.V3")
MAX_REGIONS <- 23
NO_MONTHS_PLOTS <- 4
NO_MONTHS_PLOTS_LONG <- 8
pal <- structure(c("#E9C622", "#51A4B8", "#E5BC13", "#67AFBF", "#E1B103",
                   "#82B8B6", "#E58600", "#ACC07E", "#3B9AB2", "#7F00FF", "#EB5000", "#F21A00"
), .Names = c("20A.EU2", "19A", "20D", "19B", "20C", "20E (EU1)",
              "20G", "20A", "20B", "20J/501Y.V3", "20H/501Y.V2", "20I/501Y.V1"))


############
## preprocess data
lineage$date <- sapply(strsplit(lineage$Sequence.name, split = "|", fixed = TRUE),
                       function(x) substr(paste0(tail(x, 1), "-01"), 1, 10))

lineage$sample <- gsub(sapply(strsplit(lineage$Sequence.name, split = "\\|"), `[`, 2), pattern = " ", replacement = "")

lineage$lineage_small <- fct_infreq(lineage$Lineage)
lineage$lineage_small <- fct_other(lineage$lineage_small,
                                   keep = unique(c(head(levels(lineage$lineage_small), 7), ALARM_PANGO)), other_level = "Inne")
#lineage$lineage_small <- fct_lump(lineage$lineage_small, n = 8, other_level = "Inne")


nextclade$date <- sapply(strsplit(nextclade$seqName, split = "|", fixed = TRUE),
                       function(x) substr(paste0(tail(x, 1), "-01"), 1, 10))
nextclade$sample <- gsub(sapply(strsplit(nextclade$seqName, split = "\\|"), `[`, 2), pattern = " ", replacement = "")
nextclade$clade_small <- fct_infreq(nextclade$clade)
nextclade$clade_small <- fct_lump(nextclade$clade_small, n = 12, other_level = "Inne")

# -------
# Liczba na tydzień
for (lang in langs) {
	plots_output[[lang]][['pl_seq_1']] <-
	  ggplot(lineage, aes(ymd(date) - wday(ymd(date)))) +
	  geom_histogram(binwidth = 7, color = "white") +
	  theme_minimal(base_family = 'Arial') +
	  scale_x_date("", date_breaks = "2 months", date_labels = "%m") +
	  scale_y_continuous("", expand = c(0,0)) +
	  ggtitle(descriptions[[lang]]["pl_seq_1_tit", "names"])
}

# ---------------

t_cou_lin <- table(lineage$date)
df <- as.data.frame(t_cou_lin)

for (lang in langs) {
	plots_output[[lang]][['pl_seq_2']] <-
	  ggplot(df, aes(ymd(Var1), ymin = 0, ymax = cumsum(Freq))) +
	  pammtools::geom_stepribbon() + geom_hline(yintercept = 0) +
	  theme_minimal(base_family = 'Arial') +
	  scale_x_date("", date_breaks = "2 months", date_labels = "%m") +
	  scale_y_continuous("", expand = c(0,0)) +
	  ggtitle(descriptions[[lang]]["pl_seq_2_tit", "names"])
}

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
                     date = as.character(ymd(lineage_date) %m-% months(NO_MONTHS_PLOTS)),
                     n = max(t_cou_lin[nrow(t_cou_lin),]))

for (lang in langs) {
	plots_output[[lang]][['pl_war_1']] <-
	  ggplot(df3, aes(ymd(date), ymax=n, ymin=0, fill = variant %in% ALARM_PANGO)) +
	  pammtools::geom_stepribbon() +
	  geom_text(data = counts, aes(x = ymd(date), y = n, label = label, hjust = 0, vjust = 1), size=2.7) +
	  scale_fill_manual(values = c("blue4", "red4")) +
	  scale_x_date("", date_breaks = "1 month", date_labels = "%m",
	               limits = c(ymd(lineage_date) %m-% months(NO_MONTHS_PLOTS), ymd(lineage_date))) +
	  #  scale_x_date("", date_breaks = "2 months", date_labels = "%m") +
	  facet_wrap(~variant, ncol = 5) +
	  theme_minimal(base_family = 'Arial') + scale_y_continuous("", expand = c(0,0)) +
	  ggtitle(descriptions[[lang]]["pl_war_1_tit", "names"]) +
	  theme(legend.position = "none")
}

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
                     date = as.character(ymd(lineage_date) %m-% months(NO_MONTHS_PLOTS)),
                     n = max(t_cou_cla[nrow(t_cou_cla),]))

for (lang in langs) {
	plots_output[[lang]][['pl_war_3']] <-
	  ggplot(df4, aes(ymd(date), ymax=n, ymin=0, fill = grepl(variant, pattern = "501Y"))) +
	  pammtools::geom_stepribbon() +
	  geom_text(data = counts4, aes(x = ymd(date), y = n, label = label, hjust = 0, vjust = 1), size=2.7) +
	  scale_fill_manual(values = c("blue4", "red4")) +
	  scale_x_date("", date_breaks = "1 month", date_labels = "%m",
	               limits = c(ymd(lineage_date) %m-% months(NO_MONTHS_PLOTS), ymd(lineage_date))) +
	  #  scale_x_date("", date_breaks = "2 months", date_labels = "%m") +
	  facet_wrap(~variant, ncol = 6) +
	  theme_minimal(base_family = 'Arial') + scale_y_continuous("", expand = c(0,0)) +
	  ggtitle(descriptions[[lang]]["pl_war_3_tit", "names"]) +
	  theme(legend.position = "none")
}

# ----------

lineage$lineage_small <- fct_infreq(lineage$Lineage)
# concatenate rare variants
lineage$lineage_small <- fct_other(lineage$lineage_small,
                                   keep = unique(c(head(levels(lineage$lineage_small), 20), ALARM_PANGO)), other_level = "Inne")
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

for (lang in langs) {
	plots_output[[lang]][['pl_war_2']] <-
	  ggplot(df3, aes(ymd(date), y=n, color = variant %in% ALARM_PANGO, group = variant)) +
	  geom_step() +
	  geom_step(data = df3[df3$variant %in% ALARM_PANGO,], size=1.1) +
	  geom_text_repel(data = counts[counts$variant %in% ALARM_PANGO,], aes(x = ymd(lineage_date), y = label, label = variant, hjust = 0, vjust = 0.6), size=2.9, direction = "y") +
	  scale_color_manual(values = c("grey", "red3")) +
	  scale_x_date("", date_breaks = "2 weeks", date_labels = "%m/%d",
	               limits = c(ymd(lineage_date) %m-% months(NO_MONTHS_PLOTS_LONG), ymd(lineage_date))) +
	  theme_minimal(base_family = 'Arial') + scale_y_continuous("", expand = c(0,0)) +
	  ggtitle(descriptions[[lang]]["pl_war_3_tit", "names"]) +
	  theme(legend.position = "none")
}

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

for (lang in langs) {
	plots_output[[lang]][['pl_war_4']] <-
	  ggplot(df5, aes(ymd(date), y=n, color = variant %in% ALARM_CLADE, group = variant)) +
	  geom_step() +
	  geom_step(data = df5[df5$variant %in% ALARM_CLADE,], size=1.1) +
	  geom_text_repel(data = counts5[counts5$variant %in% ALARM_CLADE,], aes(x = ymd(lineage_date), y = label, label = variant, hjust = 0, vjust = 0.6), size=2.9, direction = "y") +
	  scale_color_manual(values = c("grey", "red3")) +
	  scale_x_date("", date_breaks = "2 weeks", date_labels = "%m/%d",
	               limits = c(ymd(lineage_date) %m-% months(NO_MONTHS_PLOTS_LONG), ymd(lineage_date))) +
	  theme_minimal(base_family = 'Arial') + scale_y_continuous("", expand = c(0,0)) +
	  ggtitle(descriptions[[lang]]["pl_war_4_tit", "names"]) +
	  theme(legend.position = "none")
}

############
## plots from meta data

nextclade$seqName <- gsub(nextclade$seqName, pattern = "\\|.*", replacement = "")
metadata_ext <- merge(metadata, nextclade, by.x = "accession_id", by.y = "accession_id")

for (lang in langs) {
	plots_output[[lang]][['pl_war_5']] <-
	  ggplot(metadata_ext, aes(ymd(collection_date), ymd(submission_date), color = grepl(clade_small, pattern = "501Y"))) +
	  geom_abline(slope = 1, intercept = 0, color = "grey", lty = 4) +
	  geom_abline(slope = 1, intercept = 14, color = "grey", lty = 2) +
	  geom_abline(slope = 1, intercept = 28, color = "grey", lty = 3) +
	  geom_jitter(size = 0.5) +
	  ggtitle("", descriptions[[lang]]["pl_war_5_tit", "names"]) +
	  theme_bw(base_family = 'Arial') + coord_fixed() +
	  scale_color_manual("", values = c("blue4", "red2")) +
	  scale_x_date(descriptions[[lang]]["pl_war_5_scx", "names"], date_breaks = "2 weeks", date_labels = "%m/%d",
	               limits = c(ymd(lineage_date) %m-% months(NO_MONTHS_PLOTS), ymd(lineage_date)))  +
	  scale_y_date(descriptions[[lang]]["pl_war_5_scy", "names"], date_breaks = "2 weeks", date_labels = "%m/%d",
	               limits = c(ymd(lineage_date) %m-% months(NO_MONTHS_PLOTS-1), ymd(lineage_date)))+
	  theme(legend.position = "none")
}


# --------------------------------- #
# ------------LOCATION------------- #
# --------------------------------- #

### reversed dict
## NOTE: gsub(" ", "", x) is not possible due to other countries than PL
# TODO: consider only lowercase keys

location_dict_to_from <- list(
  # https://pl.wikipedia.org/wiki/Województwo
  ######## PL

  "Dolnośląskie" =
    c(
      "Dolnoslaskie" , "dolnoslaskie"
    , " Dolnoslaskie" , " dolnoslaskie"
    , " Dolnoslaskie " , " dolnoslaskie "
    , "Dolnośląskie", "dolnośląskie"
    , " Dolnośląskie", " dolnośląskie"
    , " Dolnośląskie ", " dolnośląskie "
    , "Dolnoslakie", "dolnoslakie"
    , " Dolnoslakie", " dolnoslakie"
    , " Dolnoslakie ", " dolnoslakie "
    , "DolnoSlaskie" , "dolnoSlaskie"
    , " DolnoSlaskie" , " dolnoSlaskie"
    , " DolnoSlaskie " , " dolnoSlaskie "
    )
, "Kujawsko-Pomorskie" =
    c(
      "Kujawsko-Pomorskie" , "kujawsko-pomorskie", "Kujawsko-pomorskie"
    , " Kujawsko-Pomorskie" , " kujawsko-pomorskie", " Kujawsko-pomorskie"
    , " Kujawsko-Pomorskie " , " kujawsko-pomorskie ", " Kujawsko-pomorskie "
    )
, "Lubelskie" =
    c(
      "Lubelskie" , "lubelskie"
    , " Lubelskie", " lubelskie"
    , " Lubelskie ", " lubelskie "
    )
, "Lubuskie" =
    c(
      "Lubuskie" , "lubuskie"
    , " Lubuskie" , " lubuskie"
    , " Lubuskie " , " lubuskie "
    )
, "Łódzkie" =
    c(
      "Lodzkie", "lodzkie"
    , " Lodzkie", " lodzkie"
    , " Lodzkie ", " lodzkie "
    , "Łódzkie", "łódzkie"
    , " Łódzkie", " łódzkie"
    , " Łódzkie ", " łódzkie "
    , "Iodzkie", "lodzkie"
    , " Iodzkie", " lodzkie"
    , " Iodzkie ", " lodzkie "
    )
, "Małopolskie" =
    c(
      "Malopolskie" , "malopolskie"
    , " Malopolskie" , " malopolskie"
    , " Malopolskie " , " malopolskie "
    , "Małopolskie", "małopolskie"
    , " Małopolskie", " małopolskie"
    , " Małopolskie ", " małopolskie "
    , "Malopolska", "malopolska"
    , " Malopolska", " malopolska"
    , " Malopolska ", " malopolska "
    , "Małopolska", "małopolska"
    , " Małopolska", " małopolska"
    , " Małopolska ", " małopolska "
    , "MalOpolskie", "malOpolskie"
    , " MalOpolskie", " malOpolskie"
    , " MalOpolskie ", " malOpolskie "
    )
, "Mazowieckie" =
    c(
      "Mazowieckie", "mazowieckie"
    , " Mazowieckie", " mazowieckie"
    , " Mazowieckie ", " mazowieckie "
    , "Masovia", "masovia"
    , " Masovia", " masovia"
    , " Masovia ", " masovia "
    )
, "Opolskie" =
    c(
      "Opolskie", "opolskie"
    , " Opolskie", " opolskie"
    , " Opolskie ", " opolskie "
    )
, "Podkarpackie" =
    c(
      "Podkarpackie", "podkarpackie"
    , " Podkarpackie", " podkarpackie"
    , " Podkarpackie ", " podkarpackie "
    )
, "Podlaskie" =
    c(
      "Podlaskie", "podlaskie"
    , " Podlaskie", " podlaskie"
    , " Podlaskie ", " podlaskie "
    , "Bielsk Podlaski", "bielsk podlaski"
    , " Bielsk Podlaski", " bielsk podlaski"
    , " Bielsk Podlaski ", " bielsk podlaski "
    )
, "Pomorskie" =
    c(
      "Pomorskie", "pomorskie"
    , " Pomorskie", " pomorskie"
    , " Pomorskie ", " pomorskie "
    , "Pomerania", "pomerania"
    , " Pomerania", " pomerania"
    , " Pomerania ", " pomerania "
    , "Pomorze", "pomorze"
    , " Pomorze", " pomorze"
    , " Pomorze ", " pomorze "
    )
, "Śląskie" =
    c(
      "Slaskie", "slaskie"
    , " Slaskie", " slaskie"
    , " Slaskie ", " slaskie "
    , "Śląskie", "śląskie"
    , " Śląskie", " śląskie"
    , " Śląskie ", " śląskie "
    , "Slask", "slask"
    , " Slask", " slask"
    , " Slask ", " slask "
    )
, "Świętokrzyskie" =
    c(
      "Swietokrzyskie", "swietokrzyskie"
    , " Swietokrzyskie", " swietokrzyskie"
    , " Swietokrzyskie ", " swietokrzyskie "
    , "Świętokrzyskie", "świętokrzyskie"
    , " Świętokrzyskie", " świętokrzyskie"
    , " Świętokrzyskie ", " świętokrzyskie "
    )
, "Warmińsko-Mazurskie" =
    c(
      "Warminsko-Mazurskie", "warminsko-mazurskie", "Warminsko-mazurskie"
    , " Warminsko-Mazurskie", " warminsko-mazurskie", " Warminsko-mazurskie"
    , " Warminsko-Mazurskie ", " warminsko-mazurskie ", " Warminsko-mazurskie "
    , "Warmińsko-Mazurskie", "warmińsko-mazurskie", "Warmińsko-mazurskie"
    , " Warmińsko-Mazurskie", " warmińsko-mazurskie", " Warmińsko-mazurskie"
    , " Warmińsko-Mazurskie ", " warmińsko-mazurskie ", " Warmińsko-mazurskie "
    )
, "Wielkopolskie" =
    c(
      "Wielkopolskie", "wielkopolskie"
    , " Wielkopolskie", " wielkopolskie"
    , " Wielkopolskie ", " wielkopolskie "
    , "Wielkopolska", "wielkopolska"
    , " Wielkopolska", " wielkopolska"
    , " Wielkopolska ", " wielkopolska "
    , "WielkOpolskie", "wielkOpolskie"
    , " WielkOpolskie", " wielkOpolskie"
    , " WielkOpolskie ", " wielkOpolskie "
    )
, "Zachodniopomorskie" =
    c(
      "Zachodniopomorskie", "zachodniopomorskie"
    , " Zachodniopomorskie", " zachodniopomorskie"
    , " Zachodniopomorskie ", " zachodniopomorskie "
    , "ZachodnioPomorskie", "zachodnioPomorskie"
    , " ZachodnioPomorskie", " zachodnioPomorskie"
    , " ZachodnioPomorskie ", " zachodnioPomorskie "
    )

  ########
, "Central Bohemian Region" =
    c(
      "Central Bohemian Region", "central bohemian region"
    , " Central Bohemian Region", " central bohemian region"
    , " Central Bohemian Region ", " central bohemian region "
    , "Central Bohemia Region", "central bohemia region"
    , " Central Bohemia Region", " central bohemia region"
    , " Central Bohemia Region ", " central bohemia region "
    , "Melnik", "melnik"
    , " Melnik", " melnik"
    , " Melnik ", " melnik "
    , "Slaný", "slaný"
    , " Slaný", " slaný"
    , " Slaný ", " slaný "
    )
, "Hradec Králové Region" =
    c(
      "Hradec Králové Region", "hradec králové region"
    , " Hradec Králové Region", " hradec králové region"
    , " Hradec Králové Region ", " hradec králové region "
    , "Hradec Kralove Region", "hradec kralove region"
    , " Hradec Kralove Region", " hradec kralove region"
    , " Hradec Kralove Region ", " hradec kralove region "
    )
, "Liberec Region" =
    c(
      "Liberec Region", "liberec region"
    , " Liberec Region", " liberec region"
    , " Liberec Region ", " liberec region "
    )
, "Moravian-Silesian Region" =
    c(
      "Moravian-Silesian Region", "moravian-silesian region"
    , " Moravian-Silesian Region", " moravian-silesian region"
    , " Moravian-Silesian Region ", " moravian-silesian region "
    )
, "Northern Bohemian Region" =
    c(
      "Northern Bohemian Region", "northern bohemian region"
    , " Northern Bohemian Region", " northern bohemian region"
    , " Northern Bohemian Region ", " northern bohemian region "
    , "Northern Bohemia Region", "northern bohemia region"
    , " Northern Bohemia Region", " northern bohemia region"
    , " Northern Bohemia Region ", " northern bohemia region "
    , "North Bohemian Region", "north bohemian region"
    , " North Bohemian Region", " north bohemian region"
    , " North Bohemian Region ", " north bohemian region "
    , "North Bohemia Region", "north bohemia region"
    , " North Bohemia Region", " north bohemia region"
    , " North Bohemia Region ", " north bohemia region "
    )
, "Olomouc Region" =
    c(
      "Olomouc", "olomouc"
    , " Olomouc", " olomouc"
    , " Olomouc ", " olomouc "
    , "Olomouc Region", "olomouc region"
    , " Olomouc Region", " olomouc region"
    , " Olomouc Region ", " olomouc region "
    , "Litovel", "litovel"
    , " Litovel", " litovel"
    , " Litovel ", " litovel "
    , "Hranice na Moravě", "hranice na moravě"
    , " Hranice na Moravě", " hranice na moravě"
    , " Hranice na Moravě ", " hranice na moravě "
    , "Hranice", "hranice"
    , " Hranice", " hranice"
    , " Hranice ", " hranice "
    )
, "Pardubice Region" =
    c(
      "Pardubice Region", "pardubice region"
    , " Pardubice Region", " pardubice region"
    , " Pardubice Region ", " pardubice region "
    )
, "Plzeň Region" =
    c(
      "Plzen", "plzen"
    , " Plzen", " plzen"
    , " Plzen ", " plzen "
    , "Plzeň", "plzeň"
    , " Plzeň", " plzeň"
    , " Plzeň ", " plzeň "
    , "Plzen Region", "plzen region"
    , " Plzen Region", " plzen region"
    , " Plzen Region ", " plzen region "
    , "Plzeň Region", "plzeň region"
    , " Plzeň Region", " plzeň region"
    , " Plzeň Region ", " plzeň region "
    , "Klatovy", "klatovy"
    , " Klatovy", " klatovy"
    , " Klatovy ", " klatovy "
    , "Domažlice", "domažlice"
    , " Domažlice", " domažlice"
    , " Domažlice ", " domažlice "
    , "Pilsen", "pilsen"
    , " Pilsen", " pilsen"
    , " Pilsen ", " pilsen "
    )
, "Prague" =
    c(
      "Prague", "prague"
    , " Prague", " prague"
    , " Prague ", " prague "
    , "Prague-Miskovice", "prague-miskovice"
    , " Prague-Miskovice", " prague-miskovice"
    , " Prague-Miskovice ", " prague-miskovice "
    )
, "South Bohemian Region" =
    c(
      "South Bohemian Region", "south bohemian region"
    , " South Bohemian Region", " south bohemian region"
    , " South Bohemian Region ", " south bohemian region "
    , "South Bohemia Region", "south bohemia region"
    , " South Bohemia Region", " south bohemia region"
    , " South Bohemia Region ", " south bohemia region "
    , "Southern Bohemian Region", "southern bohemian region"
    , " Southern Bohemian Region", " southern bohemian region"
    , " Southern Bohemian Region ", " southern bohemian region "
    , "Southern Bohemia Region", "southern bohemia region"
    , " Southern Bohemia Region", " southern bohemia region"
    , " Southern Bohemia Region ", " southern bohemia region "
    )
, "South Moravian Region" =
    c(
      "South Moravian Region", "south moravian region"
    , " South Moravian Region", " south moravian region"
    , " South Moravian Region ", " south moravian region "
    , "Brno", "brno"
    , " Brno", " brno"
    , " Brno ", " brno "
    , "Breclav", "breclav"
    , " Breclav", " breclav"
    , " Breclav ", " breclav "
    )
, "Ústí nad Labem Region" =
    c(
      "Ústí nad Labem", "ústí nad labem"
    , " Ústí nad Labem", " ústí nad labem"
    , " Ústí nad Labem ", " ústí nad labem "
    , "Ústí nad Labem Region", "ústí nad labem region"
    , " Ústí nad Labem Region", " ústí nad labem region"
    , " Ústí nad Labem Region ", " ústí nad labem region "
    , "Usti nad Labem", "usti nad labem"
    , " Usti nad Labem", " usti nad labem"
    , " Usti nad Labem ", " usti nad labem "
    )
, "Vysocina Region" =
    c(
      "Vysocina Region", "vysocina region"
    , " Vysocina Region", " vysocina region"
    , " Vysocina Region ", " vysocina region "
    , "Vysocina", "vysocina"
    , " Vysocina", " vysocina"
    , " Vysocina ", " vysocina "
    , "Jihlava", "jihlava"
    , " Jihlava", " jihlava"
    , " Jihlava ", " jihlava "
    )
, "Zlín Region" =
    c(
      "Zlin", "zlin"
    , " Zlin", " zlin"
    , " Zlin ", " zlin "
    , "Zlin Region", "zlin region"
    , " Zlin Region", " zlin region"
    , " Zlin Region ", " zlin region "
    , "Zlín", "zlín"
    , " Zlín", " zlín"
    , " Zlín ", " zlín "
    , "Zlín Region", "zlín region"
    , " Zlín Region", " zlín region"
    , " Zlín Region ", " zlín region "
    )
)

reverse_dict <- function(dict) {
  # https://stackoverflow.com/a/35827024
  split(rep(names(dict), lengths(dict)), unlist(dict))
}

### proper dict
location_dict_from_to <- reverse_dict(location_dict_to_from)

### clean location
location_from <- sapply(strsplit(metadata_ext$location, split = "/"), `[`, 3, simplify = T, USE.NAMES = F)
metadata_ext$LocationRaw <- location_from
location_to <- location_dict_from_to[location_from]
location_to[is.na(names(location_to))] <- NA
metadata_ext$LocationClean <- unlist(location_to)
if (sum(!is.na(metadata_ext$LocationClean)) == 0) {
    metadata_ext$LocationClean <- unlist(location_from)
}

### print info about new misspelled data
misspelled_rows <- is.na(metadata_ext$LocationClean)
misspelled_locations <- table(metadata_ext$location[misspelled_rows])
print(paste("There are", length(misspelled_locations), "misspelled locations"))
print(paste("There are", sum(misspelled_rows), "unique misspelled rows"))
print(as.data.frame(misspelled_locations))

### PLOTS

metadata_ext$week_start <- ymd(metadata_ext$collection_date) - days(wday(ymd(metadata_ext$collection_date)))

## Do we have information about location
if (sum(!is.na(metadata_ext$LocationClean)) > 0) {
  t_dat_loc_cla <- table(metadata_ext$week_start, metadata_ext$LocationClean,
                         ifelse(grepl(metadata_ext$clade_small, pattern = ALARM_PATTERN), ALARM_MUTATION, "-"))

  t_dat_loc_cla <- data.frame(as.table(t_dat_loc_cla))

  t_dat_loc_cla$Var2 <- reorder(t_dat_loc_cla$Var2, -t_dat_loc_cla$Freq, sum)
  # concatenate regions that are rare, keep only MAX_REGIONS
  selected_regions <- head(levels(t_dat_loc_cla$Var2), MAX_REGIONS)
  n_unique_regions <- max(length(unique(selected_regions)), 1)
  try({
    metadata_ext$LocationClean <- fct_other(metadata_ext$LocationClean,
                                            keep = selected_regions,
                                            other_level = "Others")
  }, silent = TRUE)
  # calculate this table again with combined levels
  t_dat_loc_cla <- table(metadata_ext$week_start, metadata_ext$LocationClean,
                         ifelse(grepl(metadata_ext$clade_small, pattern = ALARM_PATTERN), ALARM_MUTATION, "-"))
  t_dat_loc_cla <- data.frame(as.table(t_dat_loc_cla))
  levels1 <- levels(t_dat_loc_cla$Var2)
  # regions are now concatenated


  for (lang in langs) {
  	plots_output[[lang]][['pl_loc_1']] <-
  	  ggplot(t_dat_loc_cla, aes(ymd(Var1), y=Freq, fill = Var3)) +
  	  geom_col() +
  	  #geom_text(data = counts4, aes(x = ymd(date), y = n, label = label, hjust = 0, vjust = 1), size=2.7) +
  	  scale_fill_manual(values = c("grey", "red3")) +
  	  scale_x_date("", date_breaks = "1 month", date_labels = "%m",
  	               limits = c(ymd(lineage_date) %m-% months(NO_MONTHS_PLOTS), ymd(lineage_date))) +
  	  facet_wrap(~Var2, ncol = 5) +
  	  theme_minimal(base_family = 'Arial') + scale_y_continuous("", expand = c(0,0)) +
  	  ggtitle(descriptions[[lang]]["pl_loc_1_tit", "names"]) +
  	  theme(legend.position = "none")
  }

  #
  t_dat_map <- t_dat_loc_cla %>% rename(date = Var1, name = Var2, type = Var3, count = Freq)
  #

  t_dat_loc_cla <- table(metadata_ext$week_start, metadata_ext$LocationClean,
                         ifelse(grepl(metadata_ext$clade_small, pattern = ALARM_PATTERN), ALARM_MUTATION, "-"))
  normalizer <-  t_dat_loc_cla[,,1] + t_dat_loc_cla[,,2]
  t_dat_loc_cla[,,1] <- t_dat_loc_cla[,,1] / normalizer
  t_dat_loc_cla[,,2] <- t_dat_loc_cla[,,2] /normalizer
  t_dat_loc_cla <- data.frame(as.table(t_dat_loc_cla))

  t_dat_loc_cla$Var2 <- factor(t_dat_loc_cla$Var2, levels = levels1)

  for (lang in langs) {
  	plots_output[[lang]][['pl_loc_2']] <-
   	  ggplot(t_dat_loc_cla, aes(ymd(Var1), y=Freq, fill = Var3)) +
   	  geom_col() +
   	  #  geom_text(data = counts4, aes(x = ymd(date), y = n, label = label, hjust = 0, vjust = 1), size=2.7) +
   	  scale_fill_manual(values = c("#77777777", "red3")) +
   	  scale_y_continuous("", labels = scales::percent, expand = c(0,0)) +
   	  scale_x_date("", date_breaks = "1 month", date_labels = "%m",
   	               limits = c(ymd(lineage_date) %m-% months(NO_MONTHS_PLOTS), ymd(lineage_date))) +
   	  facet_wrap(~Var2, ncol = 5) +
   	  theme_minimal(base_family = 'Arial') +
   	  ggtitle(descriptions[[lang]]["pl_loc_2_tit", "names"]) +
   	  theme(legend.position = "none")
  }

}

# --------------------------------- #
# --------------MAP---------------- #
# --------------------------------- #

if (region == "Poland") {

  ((t_dat_map %>%
      filter(ymd(date) + weeks(1) >= DATE_LAST_SAMPLE) %>%
      mutate(name = tolower(name)) -> t_map_metadata_week) %>%
     group_by(name, type) %>%
     summarise(count = sum(count))  %>%
     pivot_wider(id_cols = name, names_from = type, values_from = count) %>%
     inner_join(t_map_metadata_week %>%
                  group_by(name) %>%
                  summarise(ratio = sum(count) / sum(t_map_metadata_week$count))) -> t_map_metadata_week) %>%
    mutate(ratio = 2 * (10e12 * ratio / max(t_map_metadata_week$ratio)) ** (1/3)) -> t_map_metadata_week

  ((t_dat_map %>%
      filter(ymd(date) + months(1) >= DATE_LAST_SAMPLE) %>%
      mutate(name = tolower(name)) -> t_map_metadata_month) %>%
      group_by(name, type) %>%
      summarise(count = sum(count))  %>%
      pivot_wider(id_cols = name, names_from = type, values_from = count) %>%
      inner_join(t_map_metadata_month %>%
                   group_by(name) %>%
                   summarise(ratio = sum(count) / sum(t_map_metadata_month$count))) -> t_map_metadata_month) %>%
    mutate(ratio = 2 * (10e12 * ratio / max(t_map_metadata_month$ratio)) ** (1/3)) -> t_map_metadata_month

  map_cord <- st_read("./map/pl-voi.shp")
  map_cord <- simplify_shape(map_cord, fact = 0.15) # 0.1 oversimplifies and returns error?
  map_cord <- st_transform(map_cord, 2180) # long and lat is no longer used
  map_cord_df <- as.data.frame(st_coordinates(map_cord)) %>% rename(id = L3)
  centroid_cord <- as.data.frame(st_coordinates(st_centroid(map_cord)))

  map_metadata <- data.frame(
    id   = as.data.frame(map_cord)$JPT_KOD_JE,
    name = as.data.frame(map_cord)$JPT_NAZWA_,
    X = centroid_cord$X,
    Y  = centroid_cord$Y
  )


  for (lang in langs) {
	  pl_map_1 <- ggplot(map_cord_df) +
	    geom_polygon(aes(X, Y, group = id), color = "black", fill = "white") +
	    geom_scatterpie(data = map_metadata  %>% left_join(t_map_metadata_week, by = "name") %>% drop_na(),
	                    cols = c(ALARM_MUTATION, "-"),
	                    aes(x = X, y = Y, r = ratio, group = id)) +
	    coord_equal() +
	    scale_fill_manual(values = c("red3", "grey")) +
	    theme_void() +
	    theme(legend.position = "none") +
	    ggtitle(paste(descriptions[[lang]]["pl_map_sub1", "names"], DATE_LAST_SAMPLE)) +
	    theme(plot.title = element_text(size=12, hjust = 0.5))

	  pl_map_2 <- ggplot(map_cord_df) +
	    geom_polygon(aes(X, Y, group = id), color = "black", fill = "white") +
	    geom_scatterpie(data = map_metadata  %>% left_join(t_map_metadata_month, by = "name") %>% drop_na(),
	                    cols = c(ALARM_MUTATION, "-"),
	                    aes(x = X, y = Y, r = ratio, group = id)) +
	    coord_equal() +
	    scale_fill_manual(values = c("red3", "grey")) +
	    theme_void() +
	    theme(legend.position = "none") +
	    ggtitle(paste(descriptions[[lang]]["pl_map_sub2", "names"], DATE_LAST_SAMPLE)) +
	    theme(plot.title = element_text(size=12, hjust = 0.5))

	  plots_output[[lang]][['pl_map']] <- (pl_map_1 + pl_map_2) +
	    plot_annotation(
	      title=paste(descriptions[[lang]]["pl_map_pt1", "names"], ALARM_MUTATION, descriptions[[lang]]["pl_map_pt2", "names"]),
	      theme = theme(plot.title = element_text(size=15, hjust = 0.5))
	    )
  }
}

# --------------------------------- #
# --------------------------------- #

# -------
# Ewolucja clades


# round weeks
lineage_date_local <- lineage_date # max(as.character(df4$date)) # something is wrong with the input file

t_cou_cla <- table(ymd(nextclade$date) - days(wday(ymd(nextclade$date))), nextclade$clade_small)
df4 <- as.data.frame(as.table(t_cou_cla))
colnames(df4) <- c("date", "variant", "n")

df4$variant <- reorder(df4$variant, df4$n, tail, 1)
df4$variant <- fct_relevel(df4$variant, ALARM_CLADE, after = Inf)

df4 <- df4[df4$variant %in% names(pal),]
df4 <- df4[ymd(df4$date) > ymd(lineage_date_local) %m-% months(NO_MONTHS_PLOTS),]

for (lang in langs) {
	plots_output[[lang]][['pl_var_all_2']] <-
	  ggplot(df4, aes(ymd(date) + days(3), y=n, fill = variant)) +
	  geom_col( position = "fill", color = "white") +
	  coord_cartesian(xlim = c(ymd(lineage_date_local) %m-% months(NO_MONTHS_PLOTS), ymd(lineage_date_local)), ylim= c(0,1)) +
	  scale_x_date("", date_breaks = "1 month", date_labels = "%m",
	               limits = c(ymd(lineage_date_local) %m-% months(NO_MONTHS_PLOTS), ymd(lineage_date_local)))+
	  scale_fill_manual("", values = pal) +
	  ggtitle(descriptions[[lang]]["pl_var_all_2_tit", "names"]) +
	  theme_minimal(base_family = 'Arial') + scale_y_continuous("", expand = c(0,0), labels = scales::percent)
}

for (lang in langs) {
	plots_output[[lang]][['pl_var_all_3']] <-
	  ggplot(df4, aes(ymd(date) + days(3), y=n, fill = variant)) +
	  geom_col( position = "stack", color = "white") +
	  coord_cartesian(xlim = c(ymd(lineage_date_local) %m-% months(NO_MONTHS_PLOTS), ymd(lineage_date_local))) +
	  scale_x_date("", date_breaks = "1 month", date_labels = "%m",
	               limits = c(ymd(lineage_date_local) %m-% months(NO_MONTHS_PLOTS), ymd(lineage_date_local)))+
	  scale_fill_manual("", values = pal) +
	  ggtitle(descriptions[[lang]]["pl_var_all_3_tit", "names"]) +
	  theme_minimal(base_family = 'Arial') + scale_y_continuous("", expand = c(0,0))
}

t_cou_cla <- table(nextclade$date, nextclade$clade_small)
# add +k days for reporting lag
k <- 7
for (i in nrow(t_cou_cla):k) {
  t_cou_cla[i,] <- colSums(t_cou_cla[i-(1:k)+1,])
}

df4 <- as.data.frame(as.table(t_cou_cla))
colnames(df4) <- c("date", "variant", "n")

df4$variant <- reorder(df4$variant, df4$n, tail, 1)
df4$variant <- fct_relevel(df4$variant, ALARM_CLADE, after = Inf)

df4 <- df4[df4$variant %in% names(pal),]
df4 <- df4[ymd(df4$date) > ymd(lineage_date_local) %m-% months(NO_MONTHS_PLOTS),]

for (lang in langs) {
	plots_output[[lang]][['pl_var_all_1']] <-
	  ggplot(df4, aes(ymd(date), y=n, fill = variant)) +
	  geom_area( position = "fill", color = "white") +
	  coord_cartesian(xlim = c(ymd(lineage_date_local) %m-% months(NO_MONTHS_PLOTS), ymd(lineage_date_local)), ylim= c(0,1)) +
	  scale_x_date("", date_breaks = "1 month", date_labels = "%m",
	               limits = c(ymd(lineage_date_local) %m-% months(NO_MONTHS_PLOTS), ymd(lineage_date_local)))+
	  scale_fill_manual("", values = pal) +
	  ggtitle(descriptions[[lang]]["pl_var_all_1_tit", "names"]) +
	  theme_minimal(base_family = 'Arial') + scale_y_continuous("", expand = c(0,0), labels = scales::percent)
}

# profiles

t_cou_cla <- apply(t_cou_cla, 1, function(x) x / sum(x))
t_cou_cla <- t(t_cou_cla)

df5 <- as.data.frame(as.table(t_cou_cla))
colnames(df5) <- c("date", "variant", "n")

df5$variant <- reorder(df5$variant, df5$n, tail, 1)
df5$variant <- fct_relevel(df5$variant, ALARM_CLADE, after = Inf)

df5 <- df5[df5$variant %in% names(pal),]
df5 <- df5[ymd(df5$date) > ymd(lineage_date_local) %m-% months(NO_MONTHS_PLOTS),]

for (lang in langs) {
	plots_output[[lang]][['pl_var_all_4']] <-
	  ggplot(na.omit(df5[df5$n > 0 & df5$n < 1,]), aes(ymd(date), y=n, color = variant)) +
	  geom_point( ) +
	  scale_x_date("", date_breaks = "1 month", date_labels = "%m",
	               limits = c(ymd(lineage_date_local) %m-% months(NO_MONTHS_PLOTS), ymd(lineage_date_local)))+
	  theme_minimal(base_family = 'Arial') +
	  geom_smooth(data = df5[(df5$variant %in% c("20I/501Y.V1", "20A", "20B")) &
	                           (ymd(df5$date) > ymd(lineage_date_local) %m-% months(2)),],
	              se = FALSE, span = 1) +
	  scale_y_continuous("",expand = c(0,0),
	                     breaks = c(0.01,0.1,0.25,0.5,0.75,0.9, 0.99), limits = c(0,1)) +
	  scale_color_manual("", values = pal) +
	  ggtitle(descriptions[[lang]]["pl_var_all_4_tit", "names"]) +
	  theme_minimal(base_family = 'Arial') +
	  coord_cartesian(xlim = c(ymd(lineage_date_local) %m-% months(NO_MONTHS_PLOTS), ymd(lineage_date_local)))
}


############
## update HTML file
t_cou_lin <- table(lineage$date, lineage$lineage_small)
warianty <- head(colnames(t_cou_lin)[-ncol(t_cou_lin)],7)
warianty_list <- paste0(paste0('<a href="https://cov-lineages.org/lineages/lineage_',warianty,'.html">',warianty,'</a>'), collapse = ",\n")
warianty2 <- head(colnames(t_cou_cla),5)
warianty2_list <- paste0(paste0('<a href="https://www.cdc.gov/coronavirus/2019-ncov/more/science-and-research/scientific-brief-emerging-variants.html">',warianty2,'</a>'), collapse = ",\n")

placeholders <- list(
	DATE = gsub("/", "-", lineage_date),
	NUMBER = nrow(lineage),
	DATELAST = max(lineage$date),
	VARIANTSLIST = warianty_list,
	VARIANTS = length(unique(lineage$Lineage)),
	VARIANTSLIST2 = warianty2_list,
	VARIANTS2 = length(colnames(t_cou_cla))
)
write(toJSON(placeholders, auto_unbox=TRUE), paste0(output_dir, '/placeholders.json'))
file.copy('./index_source.html', paste0(output_dir, '/index.html'), overwrite=TRUE)

i18n <- lapply(langs, function(lang) {
	i18n_table <- read.table(paste0("lang_", lang, ".txt"), sep=":", header = TRUE, fileEncoding = "UTF-8", quote=NULL)
	# Transform table to dictionary
	obj = as.list(i18n_table[,"names"])
	names(obj) <- i18n_table[,"tag"]
	obj
})
names(i18n) <- langs
write(toJSON(i18n, auto_unbox=TRUE), paste0(output_dir, '/i18n.json'))

############
## save plots
for (lang in langs) {
	print(paste0('Saving plots in ', lang))
	plots <- plots_output[[lang]]
	dir_prefix <- paste0(output_dir, '/images/', lang, '/')
	dir.create(dir_prefix, recursive=TRUE, showWarnings=FALSE)

	ggsave(plot = plots[['pl_seq_1']], file=paste0(dir_prefix, "liczba_seq_1.svg"), width=4, height=2.5)
	ggsave(plot = plots[['pl_seq_2']], file=paste0(dir_prefix, "liczba_seq_2.svg"), width=4, height=2.5)

	if (sum(!is.na(metadata_ext$LocationClean)) > 0) {
		ggsave(plot = plots[['pl_loc_1']], file=paste0(dir_prefix, "liczba_loc_1.svg"), width=8, height=ceiling(n_unique_regions / 5) * 5 / 4, limitsize=FALSE)
		ggsave(plot = plots[['pl_loc_2']], file=paste0(dir_prefix, "liczba_loc_2.svg"), width=8, height=ceiling(n_unique_regions / 5) * 5 / 4, limitsize=FALSE)
	}

	ggsave(plot = plots[['pl_war_1']], file=paste0(dir_prefix, "liczba_warianty_1.svg"), width=8, height=3)
	ggsave(plot = plots[['pl_war_2']], file=paste0(dir_prefix, "liczba_warianty_2.svg"), width=8, height=3)
	ggsave(plot = plots[['pl_war_3']], file=paste0(dir_prefix, "liczba_warianty_3.svg"), width=8, height=3)
	ggsave(plot = plots[['pl_war_4']], file=paste0(dir_prefix, "liczba_warianty_4.svg"), width=8, height=3)
	ggsave(plot = plots[['pl_war_5']], file=paste0(dir_prefix, "liczba_warianty_5.png"), width=8, height=5)

	ggsave(plot = plots[['pl_var_all_1']], file=paste0(dir_prefix, "udzial_warianty_1.svg"), width=5.5, height=3.5)
	ggsave(plot = plots[['pl_var_all_2']], file=paste0(dir_prefix, "udzial_warianty_2.svg"), width=5.5, height=3.5)
	ggsave(plot = plots[['pl_var_all_3']], file=paste0(dir_prefix, "udzial_warianty_3.svg"), width=5.5, height=3.5)
	ggsave(plot = plots[['pl_var_all_4']], file=paste0(dir_prefix, "udzial_warianty_4.svg"), width=5.5, height=3.5)

	if ('pl_map' %in% names(plots)) {
		ggsave(plot = plots[['pl_map']], file=paste0(dir_prefix, "mapa_mutacje.svg"), width=10, height=5)
	}

	save(plots, file = paste0(dir_prefix, 'gg_objects.rda'))
}
