# covar 1.1.0

* transform `y` to log scale
* fix clade and pango variants in facets
* fix location sorting in facets
* set smaller padding in `html` files (`15px -> 7.5px`)
* make facet plots higher (`3 -> 5`)
* normalize the size of variants plots (also smaller legend, title)
* decrease bottom margins where there is no `xlabel` (`5.5pt -> 2pt`)

# covar 1.0.1

* fix heavy `gg_objects.rda` - filter columns before passing the data to `ggplot()`, also remove the objects from function environment

# covar 1.0.0

Functionalities for the project of SARS-CoV-2 variants monitoring:
* Website: <https://monitor.mi2.ai>
* GitHub: <https://github.com/MI2DataLab/crs19-monitor>

Implemented functions:
* `clean_metadata`, `clean_lineage`, `clean_nextclade`
* `plot_clade_facet`, `plot_clade_cumulative`, `plot_location_count`,
  `plot_location_proportion`, `plot_map`, `plot_metadata_dates`,
  `plot_pango_facet`, `plot_pango_cumulative`, `plot_sequence_count`,
  `plot_sequence_cumulative`, `plot_variant_col_fill`, `plot_variant_col_stack`,
  `plot_variant_area`, `plot_variant_point_smooth`
* `create_i18n`
* `read_sql`, `read_map`
* (internal) `reverse_dict`, (internal) `location_dict`
