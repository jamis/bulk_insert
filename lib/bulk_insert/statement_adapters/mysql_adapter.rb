require_relative 'base_adapter'

module BulkInsert
  module StatementAdapters
    class MySQLAdapter < BaseAdapter
      def insert_ignore_statement
        'IGNORE'
      end

      def on_conflict_statement(columns, _ignore, update_duplicates)
        return '' unless update_duplicates

        update_values = columns.map do |column|
          "`#{column.name}`=VALUES(`#{column.name}`)"
        end.join(', ')
        ' ON DUPLICATE KEY UPDATE ' + update_values
      end

      def primary_key_return_statement(_primary_key)
        ''
      end
    end
  end
end
