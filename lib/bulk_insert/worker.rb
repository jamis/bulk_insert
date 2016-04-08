module BulkInsert
  class Worker
    attr_reader :connection
    attr_accessor :set_size

    def initialize(connection, table_name, column_names, set_size=500)
      @connection = connection
      @set_size = set_size

      columns = connection.columns(table_name)
      column_map = columns.inject({}) { |h, c| h.update(c.name => c) }

      @columns = column_names.map { |name| column_map[name.to_s] }
      @table_name = connection.quote_table_name(table_name)
      @column_names = column_names.map { |name| connection.quote_column_name(name) }.join(",")

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

    def save!
      if pending?
        sql = "INSERT INTO #{@table_name} (#{@column_names}) VALUES "
        @now = Time.now

        rows = []
        @set.each do |row|
          values = []
          @columns.zip(row) do |column, value|
            value = @now if value == :__timestamp_placeholder
            value = column.cast_type.type_cast_for_database(value) if column
            values << @connection.quote(value)
          end
          rows << "(#{values.join(',')})"
        end

        sql << rows.join(",")
        @connection.execute(sql)

        @set.clear
      end

      self
    end
  end
end
