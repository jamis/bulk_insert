require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(*Rails.groups)
require "bulk_insert"

module Dummy
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    RAILS_VERSION = Gem.loaded_specs['rails'].version

    # Patch MySQL to execute tests
    # Mysql2::Error: All parts of a PRIMARY KEY must be NOT NULL; if you need NULL in a key, use UNIQUE instead
    if RAILS_VERSION < Gem::Version.new('4.0.0')
      # https://stackoverflow.com/a/40758542/5687152
      require 'active_record/connection_adapters/mysql2_adapter'

      class ActiveRecord::ConnectionAdapters::Mysql2Adapter
        NATIVE_DATABASE_TYPES[:primary_key] = "int(11) auto_increment PRIMARY KEY"
      end
    end

    # Patch SQLite to support multiple rails versions with the same app
    # Tests are written assuming booleans as integers
    # https://github.com/rails/rails/commit/a18cf23a9cbcbeed61e8049442640c7153e0a8fb
    if RAILS_VERSION < Gem::Version.new('5.2.0')
      # https://github.com/rails/rails/commit/52e050ed00b023968fecda82f19a858876a7c435
      require 'active_record/connection_adapters/sqlite3_adapter'
      ActiveRecord::ConnectionAdapters::SQLite3Adapter.class_eval do
        class_attribute :represent_boolean_as_integer, default: false
      # end
      # ActiveRecord::ConnectionAdapters::SQLite3::Quoting.module_eval do
        def quoted_true
          ActiveRecord::ConnectionAdapters::SQLite3Adapter.represent_boolean_as_integer ? "1".freeze : "'t'".freeze
        end

        def unquoted_true
          ActiveRecord::ConnectionAdapters::SQLite3Adapter.represent_boolean_as_integer ? 1 : "t".freeze
        end

        def quoted_false
          ActiveRecord::ConnectionAdapters::SQLite3Adapter.represent_boolean_as_integer ? "0".freeze : "'f'".freeze
        end

        def unquoted_false
          ActiveRecord::ConnectionAdapters::SQLite3Adapter.represent_boolean_as_integer ? 0 : "f".freeze
        end
      end

      ActiveRecord::ConnectionAdapters::SQLite3Adapter.represent_boolean_as_integer = true
    # https://github.com/rails/rails/commit/f59b08119bc0c01a00561d38279b124abc82561b
    elsif RAILS_VERSION < Gem::Version.new('6.1.0')
      config.active_record.sqlite3.represent_boolean_as_integer = true
    end
  end
end
