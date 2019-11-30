require_relative 'base_adapter'

module BulkInsert
  module StatementAdapters
    class SQLiteAdapter < BaseAdapter
      def insert_ignore_statement
        'OR IGNORE'
      end

      def on_conflict_statement(_columns, _ignore, _update_duplicates)
        ''
      end

      def primary_key_return_statement(_primary_key)
        ''
      end
    end
  end
end
