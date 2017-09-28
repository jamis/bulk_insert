module BulkInsert
  class Worker
    attr_reader :connection
    attr_accessor :set_size
    attr_accessor :before_save_callback
    attr_accessor :after_save_callback
    attr_accessor :adapter_name
    attr_reader :ignore, :update_duplicates

    def initialize(connection, table_name, column_names, set_size=500, ignore=false, update_duplicates=false)
      @connection = connection
      @set_size = set_size

      @adapter_name = connection.adapter_name
      # INSERT IGNORE only fails inserts with duplicate keys or unallowed nulls not the whole set of inserts
      @ignore = ignore
      @update_duplicates = update_duplicates

      columns = connection.columns(table_name)
      column_map = columns.inject({}) { |h, c| h.update(c.name => c) }

      @columns = column_names.map { |name| column_map[name.to_s] }
      @table_name = connection.quote_table_name(table_name)
      @column_names = column_names.map { |name| connection.quote_column_name(name) }.join(",")

      @before_save_callback = nil
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

    def before_save(&block)
      @before_save_callback = block
    end

    def after_save(&block)
      @after_save_callback = block
    end

    def save!
      if pending?
        @before_save_callback.(@set) if @before_save_callback
        compose_insert_query.tap { |query| @connection.execute(query) if query }
        @after_save_callback.() if @after_save_callback
        @set.clear
      end

      self
    end

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

      if !rows.empty?
        sql << rows.join(",")
        sql << on_conflict_statement
        sql
      else
        false
      end
    end

    def insert_sql_statement
      "INSERT #{insert_ignore} INTO #{@table_name} (#{@column_names}) VALUES "
    end

    def insert_ignore
      if ignore
        case adapter_name
        when /^mysql/i
          'IGNORE'
        when /\ASQLite/i # SQLite
          'OR IGNORE'
        else
          '' # Not supported
        end
      end
    end

    def on_conflict_statement
      if (adapter_name =~ /\APost(?:greSQL|GIS)/i && ignore )
        ' ON CONFLICT DO NOTHING'
      elsif adapter_name =~ /^mysql/i && update_duplicates
        update_values = @columns.map do |column|
          "#{column.name}=VALUES(#{column.name})"
        end.join(', ')
        ' ON DUPLICATE KEY UPDATE ' + update_values
      else
        ''
      end
    end
  end
end
