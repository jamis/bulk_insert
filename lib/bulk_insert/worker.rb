module BulkInsert
  class Worker
    attr_reader :connection
    attr_accessor :set_size
    attr_accessor :after_save_callback
    attr_accessor :adapter_name
    attr_reader :ignore

    def initialize(connection, table_name, column_names, set_size=500, ignore=false)
      @connection = connection
      @set_size = set_size

      @adapter_name = connection.adapter_name
      # INSERT IGNORE only fails inserts with duplicate keys or unallowed nulls not the whole set of inserts
      @ignore = ignore

      columns = connection.columns(table_name)
      column_map = columns.inject({}) { |h, c| h.update(c.name => c) }

      @columns = column_names.map { |name| column_map[name.to_s] }
      @table_name = connection.quote_table_name(table_name)
      @column_names = column_names.map { |name| connection.quote_column_name(name) }.join(",")

      @after_save_callback = nil

      @set = []
    end

    def pending?
      @set.any?
    end

    def pending_count
      @set.count
    end

    def add(values)
      save! if @set.length >= set_size

      values = values.with_indifferent_access if values.is_a?(Hash)
      mapped = @columns.map.with_index do |column, index|
          value_exists = values.is_a?(Hash) ? values.key?(column.name) : (index < values.length)
          if !value_exists
            if column.default.present?
              column.default
            elsif column.name == "created_at" || column.name == "updated_at"
              :__timestamp_placeholder
            else
              nil
            end
          else
            values.is_a?(Hash) ? values[column.name] : values[index]
          end
        end

      @set.push(mapped)
      self
    end

    def add_all(rows)
      rows.each { |row| add(row) }
      self
    end

    def after_save(&block)
      @after_save_callback = block
    end

    def save!
      if pending?
        @connection.execute(compose_insert_query)
        @after_save_callback.() if @after_save_callback
        @set.clear
      end

      self
    end

    private

    def compose_insert_query
      sql = insert_sql_statement
      @now = Time.now

      rows = []
      @set.each do |row|
        values = []
        @columns.zip(row) do |column, value|
          value = @now if value == :__timestamp_placeholder

          if ActiveRecord::VERSION::STRING >= "5.0.0"
            value = @connection.type_cast_from_column(column, value) if column
            values << @connection.quote(value)
          else
            values << @connection.quote(value, column)
          end
        end
        rows << "(#{values.join(',')})"
      end

      sql << rows.join(",")
      sql << on_conflict_statement
      sql
    end

    def insert_sql_statement
      ignore = nil
      ignore = 'IGNORE' if (adapter_name == 'MySQL') && @ignore
      "INSERT #{ignore} INTO #{@table_name} (#{@column_names}) VALUES "
    end

    def on_conflict_statement
      return ' ON CONFLICT DO NOTHING' if (adapter_name == 'PostgreSQL') && @ignore
      ''
    end
  end
end
