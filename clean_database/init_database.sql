DROP TABLE IF EXISTS substitutions;
DROP TABLE IF EXISTS sequences;

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
  our_clade TEXT NULL,
  our_pango TEXT NULL,
  gisaid_clade TEXT NULL,
  gisaid_variant TEXT NULL,
  gisaid_pango TEXT NULL
);
CREATE INDEX location_index ON sequences(continent, country);
CREATE INDEX pango_index ON sequences(our_pango);
CREATE INDEX clade_index ON sequences(our_clade);

CREATE TABLE substitutions (
  accession_id TEXT NOT NULL,
  substitution TEXT NOT NULL,
  PRIMARY KEY (accession_id, substitution),
  FOREIGN KEY (accession_id) REFERENCES sequences(accession_id)
);
