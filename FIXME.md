bin/rails test /home/travis/build/jamis/bulk_insert/test/bulk_insert/worker_test.rb:336
..F
Failure:
BulkInsertWorkerTest#test_adapter_dependent_Mysql2Spatial_methods [/home/travis/build/jamis/bulk_insert/test/bulk_insert/worker_test.rb:332]:
--- expected
+++ actual
@@ -1 +1 @@
-"INSERT IGNORE INTO `testings` (`greeting`,`age`,`happy`,`created_at`,`updated_at`,`color`) VALUES ('Yo',15,FALSE,NULL,NULL,'chartreuse')"
+"INSERT IGNORE INTO \"testings\" (\"greeting\",\"age\",\"happy\",\"created_at\",\"updated_at\",\"color\") VALUES ('Yo',15,0,NULL,NULL,'chartreuse')"
bin/rails test /home/travis/build/jamis/bulk_insert/test/bulk_insert/worker_test.rb:317
F
Failure:
BulkInsertWorkerTest#test_adapter_dependent_mysql_methods [/home/travis/build/jamis/bulk_insert/test/bulk_insert/worker_test.rb:292]:
--- expected
+++ actual
@@ -1 +1 @@
-"INSERT IGNORE INTO `testings` (`greeting`,`age`,`happy`,`created_at`,`updated_at`,`color`) VALUES ('Yo',15,FALSE,NULL,NULL,'chartreuse')"
+"INSERT IGNORE INTO \"testings\" (\"greeting\",\"age\",\"happy\",\"created_at\",\"updated_at\",\"color\") VALUES ('Yo',15,0,NULL,NULL,'chartreuse')"
bin/rails test /home/travis/build/jamis/bulk_insert/test/bulk_insert/worker_test.rb:273
F
Failure:
BulkInsertWorkerTest#test_adapter_dependent_mysql_methods_work_for_mysql2 [/home/travis/build/jamis/bulk_insert/test/bulk_insert/worker_test.rb:313]:
--- expected
+++ actual
@@ -1 +1 @@
-"INSERT IGNORE INTO `testings` (`greeting`,`age`,`happy`,`created_at`,`updated_at`,`color`) VALUES ('Yo',15,FALSE,NULL,NULL,'chartreuse') ON DUPLICATE KEY UPDATE `greeting`=VALUES(`greeting`), `age`=VALUES(`age`), `happy`=VALUES(`happy`), `created_at`=VALUES(`created_at`), `updated_at`=VALUES(`updated_at`), `color`=VALUES(`color`)"
+"INSERT IGNORE INTO \"testings\" (\"greeting\",\"age\",\"happy\",\"created_at\",\"updated_at\",\"color\") VALUES ('Yo',15,0,NULL,NULL,'chartreuse') ON DUPLICATE KEY UPDATE `greeting`=VALUES(`greeting`), `age`=VALUES(`age`), `happy`=VALUES(`happy`), `created_at`=VALUES(`created_at`), `updated_at`=VALUES(`updated_at`), `color`=VALUES(`color`)"
bin/rails test /home/travis/build/jamis/bulk_insert/test/bulk_insert/worker_test.rb:296
..F
Failure:
BulkInsertWorkerTest#test_adapter_dependent_sqlite3_methods_(with_lowercase_adapter_name) [/home/travis/build/jamis/bulk_insert/test/bulk_insert/worker_test.rb:427]:
--- expected
+++ actual
@@ -1 +1 @@
-"INSERT OR IGNORE INTO `testings` (`greeting`,`age`,`happy`,`created_at`,`updated_at`,`color`) VALUES ('Yo',15,FALSE,NULL,NULL,'chartreuse')"
+"INSERT OR IGNORE INTO \"testings\" (\"greeting\",\"age\",\"happy\",\"created_at\",\"updated_at\",\"color\") VALUES ('Yo',15,0,NULL,NULL,'chartreuse')"
bin/rails test /home/travis/build/jamis/bulk_insert/test/bulk_insert/worker_test.rb:414
......F
Failure:
BulkInsertWorkerTest#test_adapter_dependent_default_methods [/home/travis/build/jamis/bulk_insert/test/bulk_insert/worker_test.rb:266]:
Expected: "Mysql2"
  Actual: "SQLite"
bin/rails test /home/travis/build/jamis/bulk_insert/test/bulk_insert/worker_test.rb:265
F
Failure:
BulkInsertWorkerTest#test_adapter_dependent_postgresql_methods_(with_update_duplicates) [/home/travis/build/jamis/bulk_insert/test/bulk_insert/worker_test.rb:391]:
--- expected
+++ actual
@@ -1 +1 @@
-"INSERT  INTO `testings` (`greeting`,`age`,`happy`,`created_at`,`updated_at`,`color`) VALUES ('Yo',15,FALSE,NULL,NULL,'chartreuse') ON CONFLICT(greeting, age, happy) DO UPDATE SET greeting=EXCLUDED.greeting, age=EXCLUDED.age, happy=EXCLUDED.happy, created_at=EXCLUDED.created_at, updated_at=EXCLUDED.updated_at, color=EXCLUDED.color RETURNING id"
+"INSERT  INTO \"testings\" (\"greeting\",\"age\",\"happy\",\"created_at\",\"updated_at\",\"color\") VALUES ('Yo',15,0,NULL,NULL,'chartreuse') ON CONFLICT(greeting, age, happy) DO UPDATE SET greeting=EXCLUDED.greeting, age=EXCLUDED.age, happy=EXCLUDED.happy, created_at=EXCLUDED.created_at, updated_at=EXCLUDED.updated_at, color=EXCLUDED.color RETURNING id"
bin/rails test /home/travis/build/jamis/bulk_insert/test/bulk_insert/worker_test.rb:376
F
Failure:
BulkInsertWorkerTest#test_adapter_dependent_PostGIS_methods [/home/travis/build/jamis/bulk_insert/test/bulk_insert/worker_test.rb:410]:
--- expected
+++ actual
@@ -1 +1 @@
-"INSERT  INTO `testings` (`greeting`,`age`,`happy`,`created_at`,`updated_at`,`color`) VALUES ('Yo',15,FALSE,NULL,NULL,'chartreuse') ON CONFLICT DO NOTHING RETURNING id"
+"INSERT  INTO \"testings\" (\"greeting\",\"age\",\"happy\",\"created_at\",\"updated_at\",\"color\") VALUES ('Yo',15,0,NULL,NULL,'chartreuse') ON CONFLICT DO NOTHING RETURNING id"
bin/rails test /home/travis/build/jamis/bulk_insert/test/bulk_insert/worker_test.rb:395
.F
Failure:
BulkInsertWorkerTest#test_adapter_dependent_postgresql_methods_(no_ignore,_no_update_duplicates) [/home/travis/build/jamis/bulk_insert/test/bulk_insert/worker_test.rb:372]:
--- expected
+++ actual
@@ -1 +1 @@
-"INSERT  INTO `testings` (`greeting`,`age`,`happy`,`created_at`,`updated_at`,`color`) VALUES ('Yo',15,FALSE,NULL,NULL,'chartreuse') RETURNING id"
+"INSERT  INTO \"testings\" (\"greeting\",\"age\",\"happy\",\"created_at\",\"updated_at\",\"color\") VALUES ('Yo',15,0,NULL,NULL,'chartreuse') RETURNING id"
bin/rails test /home/travis/build/jamis/bulk_insert/test/bulk_insert/worker_test.rb:356
.F
Failure:
BulkInsertWorkerTest#test_add_should_default_timestamp_columns_to_current_time [/home/travis/build/jamis/bulk_insert/test/bulk_insert/worker_test.rb:40]:
Expected Sun, 07 Feb 2021 22:06:47 UTC +00:00 to be >= 2021-02-07 22:06:47 +0000.
bin/rails test /home/travis/build/jamis/bulk_insert/test/bulk_insert/worker_test.rb:33
....F
Failure:
BulkInsertWorkerTest#test_adapter_dependent_sqlite3_methods_(with_stylecase_adapter_name) [/home/travis/build/jamis/bulk_insert/test/bulk_insert/worker_test.rb:444]:
--- expected
+++ actual
@@ -1 +1 @@
-"INSERT OR IGNORE INTO `testings` (`greeting`,`age`,`happy`,`created_at`,`updated_at`,`color`) VALUES ('Yo',15,FALSE,NULL,NULL,'chartreuse')"
+"INSERT OR IGNORE INTO \"testings\" (\"greeting\",\"age\",\"happy\",\"created_at\",\"updated_at\",\"color\") VALUES ('Yo',15,0,NULL,NULL,'chartreuse')"
bin/rails test /home/travis/build/jamis/bulk_insert/test/bulk_insert/worker_test.rb:431
....F
Failure:
BulkInsertWorkerTest#test_mysql_adapter_can_update_duplicates [/home/travis/build/jamis/bulk_insert/test/bulk_insert/worker_test.rb:462]:
--- expected
+++ actual
@@ -1 +1 @@
-"INSERT  INTO `testings` (`greeting`,`age`,`happy`,`created_at`,`updated_at`,`color`) VALUES ('Yo',15,FALSE,NULL,NULL,'chartreuse') ON DUPLICATE KEY UPDATE `greeting`=VALUES(`greeting`), `age`=VALUES(`age`), `happy`=VALUES(`happy`), `created_at`=VALUES(`created_at`), `updated_at`=VALUES(`updated_at`), `color`=VALUES(`color`)"
+"INSERT  INTO \"testings\" (\"greeting\",\"age\",\"happy\",\"created_at\",\"updated_at\",\"color\") VALUES ('Yo',15,0,NULL,NULL,'chartreuse') ON DUPLICATE KEY UPDATE `greeting`=VALUES(`greeting`), `age`=VALUES(`age`), `happy`=VALUES(`happy`), `created_at`=VALUES(`created_at`), `updated_at`=VALUES(`updated_at`), `color`=VALUES(`color`)"
