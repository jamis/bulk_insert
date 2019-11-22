module BulkInsert
  module StatementAdapters
    class GenericAdapter
      def insert_ignore_statement
        ''
      end

      def on_conflict_statement(columns, ignore, update_duplicates)
        ''
      end

      def primary_key_return_statement(primary_key)
        ''
      end
    end
  end
end
