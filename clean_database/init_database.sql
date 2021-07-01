DROP TABLE IF EXISTS substitutions_bridge;
DROP TABLE IF EXISTS substitutions;
DROP TABLE IF EXISTS sequences;
DROP TABLE IF EXISTS dates;
DROP TABLE IF EXISTS pango;
DROP TABLE IF EXISTS clade;
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

CREATE TABLE clade (
  clade TEXT PRIMARY KEY NOT NULL,
  color TEXT NULL,
  is_alarm INT NOT NULL,
  name TEXT NULL
);

CREATE TABLE pango (
  pango TEXT PRIMARY KEY NOT NULL,
  color TEXT NULL,
  is_alarm INT NOT NULL,
  class TEXT NOT NULL,
  name TEXT NULL
);

CREATE TABLE sequences (
  accession_id TEXT PRIMARY KEY NOT NULL,
  passage TEXT NULL,
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
  our_clade TEXT NULL,
  our_pango TEXT NULL,
  gisaid_clade TEXT NULL,
  gisaid_variant TEXT NULL,
  gisaid_pango TEXT NULL,
  FOREIGN KEY (collection_date) REFERENCES dates(date),
  FOREIGN KEY (submission_date) REFERENCES dates(date)
  FOREIGN KEY (our_pango) REFERENCES pango(pango),
  FOREIGN KEY (gisaid_pango) REFERENCES pango(pango),
  FOREIGN KEY (our_clade) REFERENCES clade(clade),
  FOREIGN KEY (continent, country, state) REFERENCES geography(continent, country, state)
);
CREATE INDEX location_index ON sequences(continent, country);
CREATE INDEX our_pango_index ON sequences(our_pango);
CREATE INDEX gisaid_pango_index ON sequences(gisaid_pango);
CREATE INDEX our_clade_index ON sequences(our_clade);

CREATE TABLE substitutions (
  substitution_id INT PRIMARY KEY NOT NULL,
  substitution TEXT NOT NULL,
  source TEXT NOT NULL
);
CREATE INDEX substitutions_source_index ON substitutions(source);

CREATE TABLE substitutions_bridge (
  accession_id TEXT NOT NULL,
  substitution_id INT NOT NULL,
  PRIMARY KEY (accession_id, substitution_id),
  FOREIGN KEY (accession_id) REFERENCES sequences(accession_id),
  FOREIGN KEY (substitution_id) REFERENCES substitutions(substitution_id)
);
