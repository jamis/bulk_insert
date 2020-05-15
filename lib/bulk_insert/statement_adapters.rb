require_relative 'statement_adapters/generic_adapter'
require_relative 'statement_adapters/mysql_adapter'
require_relative 'statement_adapters/postgresql_adapter'
require_relative 'statement_adapters/sqlite_adapter'

module BulkInsert
  module StatementAdapters
    def adapter_for(connection)
      case connection.adapter_name
      when /^mysql/i
        MySQLAdapter.new
      when /\APost(?:greSQL|GIS)/i
        PostgreSQLAdapter.new
      when /\ASQLite/i
        SQLiteAdapter.new
      else
        GenericAdapter.new
      end
    end
    module_function :adapter_for
  end
end
