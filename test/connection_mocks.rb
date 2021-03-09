module ConnectionMocks
  DOUBLE_QUOTE_PROC = Proc.new do |value, *_column|
    return value unless value.is_a? String
    "\"#{value}\""
  end

  BACKTICK_QUOTE_PROC = Proc.new do |value, *_column|
    return value unless value.is_a? String
    '`' + value + '`'
  end

  BOOLEAN_VALUE_QUOTE_PROC = Proc.new do |value, *_column|
    case value
    when String
      "'" + value + "'"
    when TrueClass
      'TRUE'
    when FalseClass
      'FALSE'
    when NilClass
      'NULL'
    else
      value
    end
  end

  LITERAL_BOOLEAN_VALUE_QUOTE_PROC = Proc.new do |value, *_column|
    case value
    when String
      "'" + value + "'"
    when TrueClass
      "'t'"
    when FalseClass
      "'f'"
    when NilClass
      'NULL'
    else
      value
    end
  end

  DEFAULT_VALUE_QUOTE_PROC = Proc.new do |value, *_column|
    case value
    when String
      "'" + value + "'"
    when TrueClass
      1
    when FalseClass
      0
    when NilClass
      'NULL'
    else
      value
    end
  end

  ColumnMock = Struct.new(:name, :default)
  COLUMNS_MOCK_PROC =  Proc.new do |*_table_name|
    %w(id greeting age happy created_at updated_at color).zip(
      [nil, nil, nil, nil, nil, nil, "chartreuse"]
    ).map do |column_name, default|
      ColumnMock.new(column_name, default)
    end
  end

  MockTypeSerialize = Struct.new(:column) do
    def serialize(value); value; end
  end
  CAST_COLUMN_MOCK_PROC = Proc.new do |column|
    MockTypeSerialize.new(column)
  end

  def stub_connection_if_needed(connection, adapter_name)
    raise "You need to provide a block" unless block_given?
    if connection.adapter_name == adapter_name
      yield
    else
      common_mocks(connection, adapter_name) do
        case adapter_name
        when /^mysql/i
          mock_mysql_connection(connection, adapter_name) do
            yield
          end
        when /\APost(?:greSQL|GIS)/i
          mock_postgresql_connection(connection, adapter_name) do
            yield
          end
        else
          connection.stub :quote_table_name, DOUBLE_QUOTE_PROC do
            connection.stub :quote_column_name, DOUBLE_QUOTE_PROC do
              connection.stub :quote, DEFAULT_VALUE_QUOTE_PROC do
                yield
              end
            end
          end
        end
      end
    end
  end

  def common_mocks(connection, adapter_name)
    connection.stub :adapter_name, adapter_name do
      connection.stub :columns, COLUMNS_MOCK_PROC do
        if ActiveRecord::VERSION::STRING >= "5.0.0"
          connection.stub :lookup_cast_type_from_column, CAST_COLUMN_MOCK_PROC do
            yield
          end
        else
          yield
        end
      end
    end
  end

  def mock_mysql_connection(connection, adapter_name)
    connection.stub :quote_table_name, BACKTICK_QUOTE_PROC do
      connection.stub :quote_column_name, BACKTICK_QUOTE_PROC do
        connection.stub :quote, BOOLEAN_VALUE_QUOTE_PROC do
          yield
        end
      end
    end
  end

  def mock_postgresql_connection(connection, adapter_name)
    connection.stub :quote_table_name, DOUBLE_QUOTE_PROC do
      connection.stub :quote_column_name, DOUBLE_QUOTE_PROC do
        if ActiveRecord::VERSION::STRING >= "5.0.0"
          connection.stub :quote, BOOLEAN_VALUE_QUOTE_PROC do
            yield
          end
        else
          connection.stub :quote, LITERAL_BOOLEAN_VALUE_QUOTE_PROC do
            yield
          end
        end
      end
    end
  end
end
