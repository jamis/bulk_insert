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

  # ruby 2.2 reached EOL in 2018
  # https://www.ruby-lang.org/en/news/2018/06/20/support-of-ruby-2-2-has-ended/
  s.required_ruby_version = '>= 2.3.0'

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "activerecord", ">= 3.2.0"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rails", ">= 3.2.0"
end
