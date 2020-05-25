1.8.1
-----
- Worker options ignore: false and update_duplicates: false cause an error when using postgresql_adapter (#60) [@torce]

1.8.0
-----
- Abstract database-specific statements (#46) [@sobstel]
- Allow to update duplicates on conflict in PostgreSQL (#40) [@sobstel]
- Add CI on pull requests / merges (#38) [@mberlanda]

1.7.0
-----

- Reduce requirements to allow rails 3 (#31) [Dmitry Ishkov]
- Add backticks around "on duplicate key" columns (MySQL) (#33) [Mauro Berlanda]
- PostgreSQL option to return primary keys (#32) [Peter Loomis]

1.6.0
-----

- Support Mysql2 adapter (@varyform)
- Add support for `update_duplicates` (@mstruve)
- Add support for PostGIS, Mysql2Spatial (@knu)

1.5.0
-----

- "Ignore" support for SQLite [@jfiander]
- "Ignore" support for PostgreSQL [Mauro Berlanda]
- add a callback for before_save [René Sprotte]

1.4.0
-----

- better support for Rails 5
- add an option for ignoring errors on insert

1.3.0
-----

- Adds support for an "after save" callback on the worker.

1.2.0
-----

- Fix Deprecation warning with ActiveRecord 5.0.0;
