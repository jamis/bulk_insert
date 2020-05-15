module BulkInsert
  module StatementAdapters
    class BaseAdapter
      def initialize
        raise "You cannot initialize base adapter" if self.class == BaseAdapter
      end

      def insert_ignore_statement
        raise "Not implemented"
      end

      def on_conflict_statement(_columns, _ignore, _update_duplicates)
        raise "Not implemented"
      end

      def primary_key_return_statement(_primary_key)
        raise "Not implemented"
      end
    end
  end
end
