require 'test_helper'
require 'minitest/mock'

class BulkInsertTest < ActiveSupport::TestCase
  test "bulk_insert without block should return worker" do
    result = Testing.bulk_insert
    assert_kind_of BulkInsert::Worker, result
  end

  test "bulk_insert with block should yield worker" do
    result = nil
    Testing.bulk_insert { |worker| result = worker }
    assert_kind_of BulkInsert::Worker, result
  end

  test "bulk_insert with block should save automatically" do
    assert_difference "Testing.count", 1 do
      Testing.bulk_insert do |worker|
        worker.add greeting: "Hello"
      end
    end
  end

  test "bulk_insert with array should save the array immediately" do
    assert_difference "Testing.count", 2 do
      Testing.bulk_insert values: [
        [ "Hello", 15, true, "green" ],
        { greeting: "Hey", age: 20, happy: false }
      ]
    end
  end

  test "default_bulk_columns should return all columns without id" do
    default_columns = %w(greeting age happy created_at updated_at color)

    assert_equal Testing.default_bulk_columns, default_columns
  end
  
  test "raises if on_duplicate_key is not a hash" do
    assert_raise { Testing.bulk_insert(on_duplicate_key: 2) }
  end

  test "raises if on_duplicate_key is a hash without update" do
    assert_raise { Testing.bulk_insert(on_duplicate_key: { delete: 2 }) }
  end

  test "accepts on_duplicate_key argument and constructs sql_on_duplicate in the worker" do
    correct_sql_seen = false
    
    execute_stub = -> sql do
      correct_sql_seen = true if sql == "INSERT  INTO \"testings\" (\"greeting\",\"age\",\"happy\",\"created_at\",\"updated_at\",\"color\") VALUES ('Hey',20,'f',NULL,NULL,NULL) ON DUPLICATE KEY UPDATE 123"
    end  

    Testing.connection.stub :execute, execute_stub do
      Testing.bulk_insert(
        values: [["Hey", 20, false, nil, nil, nil]],
        on_duplicate_key: { update: '123'}
      )  
    end   

    assert correct_sql_seen
  end
end
