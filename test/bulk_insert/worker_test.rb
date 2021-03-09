require 'minitest/mock'
require 'test_helper'
require 'connection_mocks'

class BulkInsertWorkerTest < ActiveSupport::TestCase
  include ConnectionMocks

  setup do
    @insert = BulkInsert::Worker.new(
      Testing.connection,
      Testing.table_name,
      'id',
      %w(greeting age happy created_at updated_at color))
    @now = Time.now.utc
  end

  test "empty insert is not pending" do
    assert_equal false, @insert.pending?
  end

  test "pending_count should describe size of pending set" do
    assert_equal 0, @insert.pending_count
    @insert.add ["Hello", 15, true, @now, @now]
    assert_equal 1, @insert.pending_count
  end

  test "default set size" do
    assert_equal 500, @insert.set_size
  end

  test "adding row to insert makes insert pending" do
    @insert.add ["Hello", 15, true, @now, @now]
    assert_equal true, @insert.pending?
  end

  test "add should default timestamp columns to current time" do
    now = Time.now

    @insert.add ["Hello", 15, true]
    @insert.save!

    record = Testing.first
    assert_operator record.created_at.to_i, :>=, now.to_i
    assert_operator record.updated_at.to_i, :>=, now.to_i
  end

  test "default timestamp columns should be equivalent for the entire batch" do
    @insert.add ["Hello", 15, true]
    @insert.add ["Howdy", 20, false]
    @insert.save!

    first, second = Testing.all
    assert_equal first.created_at.to_f, second.created_at.to_f
    assert_equal first.created_at.to_f, first.updated_at.to_f
  end

  test "add should use database default values when present" do
    @insert.add greeting: "Hello", age: 20, happy: false
    @insert.save!

    record = Testing.first
    assert_equal record.color, "chartreuse"
  end

  test "explicit nil should override defaults" do
    @insert.add greeting: "Hello", age: 20, happy: false, color: nil
    @insert.save!

    record = Testing.first
    assert_nil record.color
  end

  test "add should allow values given as Hash" do
    @insert.add greeting: "Yo", age: 20, happy: false, created_at: @now, updated_at: @now
    @insert.save!

    record = Testing.first
    assert_not_nil record
    assert_equal "Yo", record.greeting
    assert_equal 20, record.age
    assert_equal false, record.happy?
  end

  test "add should save automatically when overflowing set size" do
    @insert.set_size = 1
    @insert.add ["Hello", 15, true, @now, @now]
    @insert.add ["Yo", 20, false, @now, @now]
    assert_equal 1, Testing.count
    assert_equal "Hello", Testing.first.greeting
  end

  test "add_all should append all items to the set" do
    @insert.add_all [
      [ "Hello", 15, true ],
      { greeting: "Hi", age: 55, happy: true }
    ]
    assert_equal 2, @insert.pending_count
  end

  test "save! makes insert not pending" do
    @insert.add ["Hello", 15, true, @now, @now]
    @insert.save!
    assert_equal false, @insert.pending?
  end

  test "save! when not pending should do nothing" do
    assert_no_difference 'Testing.count' do
      @insert.save!
    end
  end

  test "save! inserts pending records" do
    @insert.add ["Yo", 15, false, @now, @now]
    @insert.add ["Hello", 25, true, @now, @now]
    @insert.save!

    yo = Testing.where(greeting: 'Yo').first
    hello = Testing.where(greeting: 'Hello').first

    assert_not_nil yo
    assert_equal 15, yo.age
    assert_equal false, yo.happy?

    assert_not_nil hello
    assert_equal 25, hello.age
    assert_equal true, hello.happy?
  end

  test "save! does not add to result sets when not returning primary keys" do
    @insert.add greeting: "first"
    @insert.add greeting: "second"
    @insert.save!

    assert_equal 0, @insert.result_sets.count
  end


  test "save! adds to result sets when returning primary keys" do
    worker = BulkInsert::Worker.new(
      Testing.connection,
      Testing.table_name,
      'id',
      %w(greeting age happy created_at updated_at color),
      500,
      false,
      false,
      true
    )

    # return_primary_keys is not supported for mysql and rails < 5
    # skip is not supported in the minitest version used for testing rails 3
    return if ActiveRecord::VERSION::STRING < "5.0.0" && worker.adapter_name =~ /^mysql/i

    assert_no_difference -> { worker.result_sets.count } do
      worker.save!
    end

    worker.add greeting: "first"
    worker.add greeting: "second"
    worker.save!
    assert_equal 1, worker.result_sets.count

    worker.add greeting: "third"
    worker.add greeting: "fourth"
    worker.save!
    assert_equal 2, worker.result_sets.count
  end

  test "initialized with empty result sets array" do
    new_worker = BulkInsert::Worker.new(
      Testing.connection,
      Testing.table_name,
      'id',
      %w(greeting age happy created_at updated_at color)
    )
    assert_instance_of(Array, new_worker.result_sets)
    assert_empty new_worker.result_sets
  end

  test "save! calls the after_save handler" do
    x = 41

    @insert.after_save do
      x += 1
    end

    @insert.add ["Yo", 15, false, @now, @now]
    @insert.add ["Hello", 25, true, @now, @now]
    @insert.save!

    assert_equal 42, x
  end

  test "after_save stores a block as a proc" do
    @insert.after_save do
      "hello"
    end

    assert_equal "hello", @insert.after_save_callback.()
  end

  test "after_save_callback can be set as a proc" do
    @insert.after_save_callback = -> do
      "hello"
    end

    assert_equal "hello", @insert.after_save_callback.()
  end

  test "save! calls the before_save handler" do
    x = 41

    @insert.before_save do
      x += 1
    end

    @insert.add ["Yo", 15, false, @now, @now]
    @insert.add ["Hello", 25, true, @now, @now]
    @insert.save!

    assert_equal 42, x
  end

  test "before_save stores a block as a proc" do
    @insert.before_save do
      "hello"
    end

    assert_equal "hello", @insert.before_save_callback.()
  end

  test "before_save_callback can be set as a proc" do
    @insert.before_save_callback = -> do
      "hello"
    end

    assert_equal "hello", @insert.before_save_callback.()
  end

  test "before_save can manipulate the set" do
    @insert.before_save do |set|
      set.reject!{|row| row[0] == "Yo"}
    end

    @insert.add ["Yo", 15, false, @now, @now]
    @insert.add ["Hello", 25, true, @now, @now]
    @insert.save!

    yo = Testing.where(greeting: 'Yo').first
    hello = Testing.where(greeting: 'Hello').first

    assert_nil yo
    assert_not_nil hello
  end

  test "save! doesn't blow up if before_save emptying the set" do
    @insert.before_save do |set|
      set.clear
    end

    @insert.add ["Yo", 15, false, @now, @now]
    @insert.add ["Hello", 25, true, @now, @now]
    @insert.save!

    yo = Testing.where(greeting: 'Yo').first
    hello = Testing.where(greeting: 'Hello').first

    assert_nil yo
    assert_nil hello
  end

  test "adapter dependent SQLite methods" do
    connection = Testing.connection
    stub_connection_if_needed(connection, 'SQLite') do
      sqlite_worker = BulkInsert::Worker.new(
        connection,
        Testing.table_name,
        'id',
        %w(greeting age happy created_at updated_at color),
        500 # batch size
      )

      assert_equal sqlite_worker.adapter_name, 'SQLite'
      assert_equal sqlite_worker.insert_sql_statement, "INSERT  INTO \"testings\" (\"greeting\",\"age\",\"happy\",\"created_at\",\"updated_at\",\"color\") VALUES "

      sqlite_worker.add ["Yo", 15, false, nil, nil]
      assert_equal sqlite_worker.compose_insert_query, "INSERT  INTO \"testings\" (\"greeting\",\"age\",\"happy\",\"created_at\",\"updated_at\",\"color\") VALUES ('Yo',15,0,NULL,NULL,'chartreuse')"
    end
  end

  test "adapter dependent MySQL methods" do
    connection = Testing.connection
    stub_connection_if_needed(connection, 'mysql') do
      mysql_worker = BulkInsert::Worker.new(
        connection,
        Testing.table_name,
        'id',
        %w(greeting age happy created_at updated_at color),
        500, # batch size
        true  # ignore
      )

      assert_equal mysql_worker.adapter_name, 'mysql'
      assert_equal (mysql_worker.adapter_name == 'mysql'), true
      assert_equal mysql_worker.ignore, true
      assert_equal ((mysql_worker.adapter_name == 'mysql') & mysql_worker.ignore), true

      mysql_worker.add ["Yo", 15, false, nil, nil]

      assert_statement_adapter mysql_worker, 'BulkInsert::StatementAdapters::MySQLAdapter'
      assert_equal mysql_worker.compose_insert_query, "INSERT IGNORE INTO `testings` (`greeting`,`age`,`happy`,`created_at`,`updated_at`,`color`) VALUES ('Yo',15,FALSE,NULL,NULL,'chartreuse')"
    end
  end

  test "adapter dependent mysql methods work for mysql2" do
    connection = Testing.connection
    stub_connection_if_needed(connection, 'mysql2') do
      mysql_worker = BulkInsert::Worker.new(
        connection,
        Testing.table_name,
        'id',
        %w(greeting age happy created_at updated_at color),
        500, # batch size
        true, # ignore
        true) # update_duplicates

      assert_equal mysql_worker.adapter_name, 'mysql2'
      assert mysql_worker.ignore

      mysql_worker.add ["Yo", 15, false, nil, nil]

      assert_statement_adapter mysql_worker, 'BulkInsert::StatementAdapters::MySQLAdapter'
      assert_equal mysql_worker.compose_insert_query, "INSERT IGNORE INTO `testings` (`greeting`,`age`,`happy`,`created_at`,`updated_at`,`color`) VALUES ('Yo',15,FALSE,NULL,NULL,'chartreuse') ON DUPLICATE KEY UPDATE `greeting`=VALUES(`greeting`), `age`=VALUES(`age`), `happy`=VALUES(`happy`), `created_at`=VALUES(`created_at`), `updated_at`=VALUES(`updated_at`), `color`=VALUES(`color`)"
    end
  end

  test "adapter dependent Mysql2Spatial methods" do
    connection = Testing.connection
    stub_connection_if_needed(connection, 'mysql2spatial') do
      mysql_worker = BulkInsert::Worker.new(
        connection,
        Testing.table_name,
        'id',
        %w(greeting age happy created_at updated_at color),
        500, # batch size
        true) # ignore

      assert_equal mysql_worker.adapter_name, 'mysql2spatial'

      mysql_worker.add ["Yo", 15, false, nil, nil]

      assert_statement_adapter mysql_worker, 'BulkInsert::StatementAdapters::MySQLAdapter'
      assert_equal mysql_worker.compose_insert_query, "INSERT IGNORE INTO `testings` (`greeting`,`age`,`happy`,`created_at`,`updated_at`,`color`) VALUES ('Yo',15,FALSE,NULL,NULL,'chartreuse')"
    end
  end

  test "adapter dependent postgresql methods" do
    connection = Testing.connection
    stub_connection_if_needed(connection, 'PostgreSQL') do
      pgsql_worker = BulkInsert::Worker.new(
        connection,
        Testing.table_name,
        'id',
        %w(greeting age happy created_at updated_at color),
        500, # batch size
        true, # ignore
        false, # update duplicates
        true # return primary keys
      )

      pgsql_worker.add ["Yo", 15, false, nil, nil]

      assert_statement_adapter pgsql_worker, 'BulkInsert::StatementAdapters::PostgreSQLAdapter'

      if ActiveRecord::VERSION::STRING >= "5.0.0"
        assert_equal pgsql_worker.compose_insert_query, "INSERT  INTO \"testings\" (\"greeting\",\"age\",\"happy\",\"created_at\",\"updated_at\",\"color\") VALUES ('Yo',15,FALSE,NULL,NULL,'chartreuse') ON CONFLICT DO NOTHING RETURNING id"
      else
        assert_equal pgsql_worker.compose_insert_query, "INSERT  INTO \"testings\" (\"greeting\",\"age\",\"happy\",\"created_at\",\"updated_at\",\"color\") VALUES ('Yo',15,'f',NULL,NULL,'chartreuse') ON CONFLICT DO NOTHING RETURNING id"
      end
    end
  end

  test "adapter dependent postgresql methods (no ignore, no update_duplicates)" do
    connection = Testing.connection
    stub_connection_if_needed(connection, 'PostgreSQL') do
      pgsql_worker = BulkInsert::Worker.new(
        connection,
        Testing.table_name,
        'id',
        %w(greeting age happy created_at updated_at color),
        500, # batch size
        false, # ignore
        false, # update duplicates
        true # return primary keys
      )

      pgsql_worker.add ["Yo", 15, false, nil, nil]

      assert_statement_adapter pgsql_worker, 'BulkInsert::StatementAdapters::PostgreSQLAdapter'

      if ActiveRecord::VERSION::STRING >= "5.0.0"
        assert_equal pgsql_worker.compose_insert_query, "INSERT  INTO \"testings\" (\"greeting\",\"age\",\"happy\",\"created_at\",\"updated_at\",\"color\") VALUES ('Yo',15,FALSE,NULL,NULL,'chartreuse') RETURNING id"
      else
        assert_equal pgsql_worker.compose_insert_query, "INSERT  INTO \"testings\" (\"greeting\",\"age\",\"happy\",\"created_at\",\"updated_at\",\"color\") VALUES ('Yo',15,'f',NULL,NULL,'chartreuse') RETURNING id"
      end
    end
  end

  test "adapter dependent postgresql methods (with update_duplicates)" do
    connection = Testing.connection
    stub_connection_if_needed(connection, 'PostgreSQL') do
      pgsql_worker = BulkInsert::Worker.new(
        connection,
        Testing.table_name,
        'id',
        %w(greeting age happy created_at updated_at color),
        500, # batch size
        false, # ignore
        %w(greeting age happy), # update duplicates
        true # return primary keys
      )
      pgsql_worker.add ["Yo", 15, false, nil, nil]

      assert_statement_adapter pgsql_worker, 'BulkInsert::StatementAdapters::PostgreSQLAdapter'

      if ActiveRecord::VERSION::STRING >= "5.0.0"
        assert_equal pgsql_worker.compose_insert_query, "INSERT  INTO \"testings\" (\"greeting\",\"age\",\"happy\",\"created_at\",\"updated_at\",\"color\") VALUES ('Yo',15,FALSE,NULL,NULL,'chartreuse') ON CONFLICT(greeting, age, happy) DO UPDATE SET greeting=EXCLUDED.greeting, age=EXCLUDED.age, happy=EXCLUDED.happy, created_at=EXCLUDED.created_at, updated_at=EXCLUDED.updated_at, color=EXCLUDED.color RETURNING id"
      else
        assert_equal pgsql_worker.compose_insert_query, "INSERT  INTO \"testings\" (\"greeting\",\"age\",\"happy\",\"created_at\",\"updated_at\",\"color\") VALUES ('Yo',15,'f',NULL,NULL,'chartreuse') ON CONFLICT(greeting, age, happy) DO UPDATE SET greeting=EXCLUDED.greeting, age=EXCLUDED.age, happy=EXCLUDED.happy, created_at=EXCLUDED.created_at, updated_at=EXCLUDED.updated_at, color=EXCLUDED.color RETURNING id"
      end
    end
  end

  test "adapter dependent PostGIS methods" do
    connection = Testing.connection
    stub_connection_if_needed(connection, 'postgis') do
      pgsql_worker = BulkInsert::Worker.new(
        connection,
        Testing.table_name,
        'id',
        %w(greeting age happy created_at updated_at color),
        500, # batch size
        true, # ignore
        false, # update duplicates
        true # return primary keys
      )
      pgsql_worker.add ["Yo", 15, false, nil, nil]

      assert_statement_adapter pgsql_worker, 'BulkInsert::StatementAdapters::PostgreSQLAdapter'

      if ActiveRecord::VERSION::STRING >= "5.0.0"
        assert_equal pgsql_worker.compose_insert_query, "INSERT  INTO \"testings\" (\"greeting\",\"age\",\"happy\",\"created_at\",\"updated_at\",\"color\") VALUES ('Yo',15,FALSE,NULL,NULL,'chartreuse') ON CONFLICT DO NOTHING RETURNING id"
      else
        assert_equal pgsql_worker.compose_insert_query, "INSERT  INTO \"testings\" (\"greeting\",\"age\",\"happy\",\"created_at\",\"updated_at\",\"color\") VALUES ('Yo',15,'f',NULL,NULL,'chartreuse') ON CONFLICT DO NOTHING RETURNING id"
      end
    end
  end

  test "adapter dependent sqlite3 methods (with lowercase adapter name)" do
    connection = Testing.connection
    stub_connection_if_needed(connection, 'sqlite3') do
      sqlite_worker = BulkInsert::Worker.new(
        Testing.connection,
        Testing.table_name,
        'id',
        %w(greeting age happy created_at updated_at color),
        500, # batch size
        true) # ignore
      sqlite_worker.adapter_name = 'sqlite3'
      sqlite_worker.add ["Yo", 15, false, nil, nil]

      assert_statement_adapter sqlite_worker, 'BulkInsert::StatementAdapters::SQLiteAdapter'
      assert_equal sqlite_worker.compose_insert_query, "INSERT OR IGNORE INTO \"testings\" (\"greeting\",\"age\",\"happy\",\"created_at\",\"updated_at\",\"color\") VALUES ('Yo',15,0,NULL,NULL,'chartreuse')"
    end
  end

  test "adapter dependent sqlite3 methods (with stylecase adapter name)" do
    connection = Testing.connection
    stub_connection_if_needed(connection, 'SQLite') do
      sqlite_worker = BulkInsert::Worker.new(
        connection,
        Testing.table_name,
        'id',
        %w(greeting age happy created_at updated_at color),
        500, # batch size
        true) # ignore
      sqlite_worker.adapter_name = 'SQLite'
      sqlite_worker.add ["Yo", 15, false, nil, nil]

      assert_statement_adapter sqlite_worker, 'BulkInsert::StatementAdapters::SQLiteAdapter'
      assert_equal sqlite_worker.compose_insert_query, "INSERT OR IGNORE INTO \"testings\" (\"greeting\",\"age\",\"happy\",\"created_at\",\"updated_at\",\"color\") VALUES ('Yo',15,0,NULL,NULL,'chartreuse')"
    end
  end

  test "mysql adapter can update duplicates" do
    connection = Testing.connection
    stub_connection_if_needed(connection, 'mysql') do
      mysql_worker = BulkInsert::Worker.new(
        connection,
        Testing.table_name,
        'id',
        %w(greeting age happy created_at updated_at color),
        500, # batch size
        false, # ignore
        true # update_duplicates
      )
      mysql_worker.add ["Yo", 15, false, nil, nil]

      assert_statement_adapter mysql_worker, 'BulkInsert::StatementAdapters::MySQLAdapter'
      assert_equal mysql_worker.compose_insert_query, "INSERT  INTO `testings` (`greeting`,`age`,`happy`,`created_at`,`updated_at`,`color`) VALUES ('Yo',15,FALSE,NULL,NULL,'chartreuse') ON DUPLICATE KEY UPDATE `greeting`=VALUES(`greeting`), `age`=VALUES(`age`), `happy`=VALUES(`happy`), `created_at`=VALUES(`created_at`), `updated_at`=VALUES(`updated_at`), `color`=VALUES(`color`)"
    end
  end

  def assert_statement_adapter(worker, adapter_name)
    assert_equal worker.instance_variable_get(:@statement_adapter).class.to_s, adapter_name
  end
end
