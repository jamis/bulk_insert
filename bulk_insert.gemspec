$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "bulk_insert/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "bulk_insert"
  s.version     = BulkInsert::VERSION
  s.authors     = ["Jamis Buck", "Mauro Berlanda"]
  s.email       = ["jamis@jamisbuck.org", "mauro.berlanda@gmail.com"]
  s.homepage    = "http://github.com/jamis/bulk_insert"
  s.summary     = "An helper for doing batch (single-statement) inserts in ActiveRecord"
  s.description = "Faster inserts! Insert N records in a single statement."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "activerecord", ">= 3.2.0"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rails", ">= 3.2.0"
end
