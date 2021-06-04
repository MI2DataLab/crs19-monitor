CREATE TABLE IF NOT EXISTS nodes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  iso_code TEXT NULL,
  lat FLOAT NULL,
  lng FLOAT NULL
);

CREATE TABLE IF NOT EXISTS mappings (
  parent_id INT NOT NULL,
  simple_name TEXT NOT NULL,
  node_id INT NOT NULL,
  count INT DEFAULT 0,
  PRIMARY KEY (parent_id, simple_name),
  FOREIGN KEY (parent_id) REFERENCES nodes(id),
  FOREIGN KEY (node_id) REFERENCES nodes(id)
);

INSERT OR IGNORE INTO nodes (id, name) VALUES(1, 'World');
