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

  test "bulk_insert with array should save the array immediately" do
    assert_difference "Testing.count", 2 do
      Testing.bulk_insert values: [
        [ "Hello", 15, true, Time.now, Time.now, "green" ],
        { greeting: "Hey", age: 20, happy: false }
      ]
    end
  end

  test "ids returned in the same order as the records appear in the insert statement" do
    attributes_for_insertion = (0..99).map { |i| { age: i } }
    result_set = Testing.bulk_insert values: attributes_for_insertion

    returned_ids = result_set.map {|result| result.fetch("id").to_i }
    expected_age_for_id_hash = {}
    returned_ids.map.with_index do |id, age|
      expected_age_for_id_hash[id] = age
    end

    new_saved_records = Testing.find(returned_ids)
    new_saved_records.each do |record|
      assert_same(expected_age_for_id_hash[record.id], record.age)
    end
  end

  test "default_bulk_columns should return all columns without id" do
    default_columns = %w(greeting age happy created_at updated_at color)

    assert_equal Testing.default_bulk_columns, default_columns
  end

end
