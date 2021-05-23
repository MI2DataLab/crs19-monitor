CREATE TABLE IF NOT EXISTS simplified (
  continent TEXT NOT NULL,
  country TEXT NOT NULL,
  simple_name TEXT NOT NULL,
  full_name TEXT,
  count INT DEFAULT 0,
  PRIMARY KEY (continent, country, simple_name)
);
