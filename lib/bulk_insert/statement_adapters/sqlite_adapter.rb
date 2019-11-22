module BulkInsert
  module StatementAdapters
    class SQLiteAdapter
      def insert_ignore_statement
        'OR IGNORE'
      end

      def on_conflict_ignore_statement
      end

      def on_conflict_update_statement
      end

      def primary_key_return_statement
      end
    end
  end
end
