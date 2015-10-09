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

    def add(values)
      save! if @set.length >= set_size

      values = values.with_indifferent_access if values.is_a?(Hash)
      mapped = @columns.map.with_index do |column, index|
          value = values.is_a?(Hash) ? values[column.name] : values[index]
          if value.nil?
            if column.name == "created_at" || column.name == "updated_at"
              Time.now
            else
              value
            end
          else
            value
          end
        end

      @set.push(mapped)
    end

    def save!
      if pending?
        sql = "INSERT INTO #{@table_name} (#{@column_names}) VALUES "

        rows = []
        @set.each do |row|
          values = []
          @columns.zip(row) do |column, value|
            values << @connection.quote(value, column)
          end
          rows << "(#{values.join(',')})"
        end

        sql << rows.join(",")
        @connection.execute(sql)

        @set.clear
      end
    end
  end
end
