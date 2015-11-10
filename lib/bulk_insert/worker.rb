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
        @now = Time.now

        rows = []
        table = @table_name.gsub('"', '')
        primary_key = @connection.primary_key(table)
        prefetch = @connection.prefetch_primary_key?(table)
        seq_name = @connection.pk_and_sequence_for(table)[1] if prefetch

        rows = []
        @set.each do |row|
          values = []
          @columns.zip(row) do |column, value|
            if prefetch && column.name == primary_key
              value = @connection.next_sequence_value(seq_name)
            elsif value == :__timestamp_placeholder
              value = @now
            end

            values << @connection.quote(value, column)
          end
          rows << values.join(', ')
        end

        case database_type
        when :oracle_enhanced
          sql = oracle_strategy(rows)
        else
          sql = sqlite3_strategy(rows)
        end
        @connection.execute(sql)

        @set.clear
      end

      self
    end

    private

    def database_type
      @connection.adapter_name.underscore.to_sym
    end

    def sqlite3_strategy(rows)
      sql = "INSERT INTO #{@table_name} (#{@column_names}) VALUES "
      sql << rows.collect{|row| "(#{row})"}.join(',')
    end

    def oracle_strategy(rows)
      sql = "INSERT ALL "
      sql << rows.collect{|row| "INTO #{@table_name} (#{@column_names}) VALUES (#{row}) "}.join("\n")
      sql << "SELECT 1 FROM DUAL"
    end
  end
end
