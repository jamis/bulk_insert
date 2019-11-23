module BulkInsert
  module StatementAdapters
    class SQLiteAdapter
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
