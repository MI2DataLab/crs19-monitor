DROP TABLE IF EXISTS sequences;
DROP TABLE IF EXISTS dates;
DROP TABLE IF EXISTS pango;
DROP TABLE IF EXISTS geography;

CREATE TABLE geography (
  continent TEXT NOT NULL,
  country TEXT NOT NULL,
  state TEXT NOT NULL,
  continent_iso_code TEXT NULL,
  country_iso_code TEXT NULL,
  state_iso_code TEXT NULL,
  continent_lat FLOAT NULL,
  country_lat FLOAT NULL,
  state_lat FLOAT NULL,
  continent_lng FLOAT NULL,
  country_lng FLOAT NULL,
  state_lng FLOAT NULL,
  PRIMARY KEY(continent, country, state)
);

CREATE TABLE dates (
  date TEXT PRIMARY KEY NOT NULL,
  year INT NOT NULL,
  month INT NOT NULL,
  day INT NOT NULL,
  week INT NOT NULL,
  weekday INT NOT NULL,
  week_start TEXT NOT NULL,
  month_start TEXT NOT NULL,
  is_weekend INT NOT NULL
);


CREATE TABLE pango (
  pango TEXT PRIMARY KEY NOT NULL,
  color TEXT NULL,
  is_alarm INT NOT NULL,
  class TEXT NOT NULL,
  class_root TEXT NOT NULL,
  name TEXT NULL
);

CREATE TABLE sequences (
  accession_id TEXT PRIMARY KEY NOT NULL,
  submission_date TEXT NULL,
  collection_date TEXT NULL,
  host TEXT NULL,
  continent TEXT NULL,
  country TEXT NULL,
  state TEXT NULL,
  originating_lab TEXT NULL,
  submitting_lab TEXT NULL,
  min_age INT NULL,
  max_age INT NULL,
  sex TEXT NULL,
  our_pango TEXT NULL,
  gisaid_clade TEXT NULL,
  gisaid_nextstrain_clade TEXT NULL,
  gisaid_pango TEXT NULL,
  strain TEXT NULL,
  virus TEXT NULL,
  segment TEXT NULL,
  FOREIGN KEY (collection_date) REFERENCES dates(date),
  FOREIGN KEY (submission_date) REFERENCES dates(date)
  FOREIGN KEY (our_pango) REFERENCES pango(pango),
  FOREIGN KEY (gisaid_pango) REFERENCES pango(pango),
  FOREIGN KEY (continent, country, state) REFERENCES geography(continent, country, state)
);
CREATE INDEX location_index ON sequences(continent, country);
CREATE INDEX our_pango_index ON sequences(our_pango);
CREATE INDEX gisaid_pango_index ON sequences(gisaid_pango);
