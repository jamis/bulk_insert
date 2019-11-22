module BulkInsert
  module StatementAdapters
    class MySQLAdapter
      def insert_ignore_statement
        'IGNORE'
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
