require 'test_helper'

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

  test "worker should not have any result sets without option for returning primary keys" do
    worker = Testing.bulk_insert
    worker.add greeting: "hello"
    worker.save!
    assert_empty worker.result_sets
  end

  test "with option to return primary keys, worker should have result sets" do
    worker = Testing.bulk_insert(return_primary_keys: true)
    worker.add greeting: "yo"

    # return_primary_keys is not supported for mysql and rails < 5
    # this test ensures that the case is covered in the CI and handled as expected
    if ActiveRecord::VERSION::STRING < "5.0.0" && worker.adapter_name =~ /^mysql/i
      error = assert_raise(ArgumentError) { worker.save! }
      assert_equal error.message, "BulkInsert does not support @return_primary_keys for mysql and rails < 5"
    else
      worker.save!
      assert_equal 1, worker.result_sets.count
    end
  end

  test "bulk_insert with array should save the array immediately" do
    assert_difference "Testing.count", 2 do
      Testing.bulk_insert values: [
        [ "Hello", 15, true ],
        { greeting: "Hey", age: 20, happy: false }
      ]
    end
  end

  test "default_bulk_columns should return all columns without id" do
    default_columns = %w(greeting age happy created_at updated_at color)

    assert_equal Testing.default_bulk_columns, default_columns
  end

end
