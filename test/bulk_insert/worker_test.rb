require 'test_helper'

class BulkInsertWorkerTest < ActiveSupport::TestCase
  setup do
    @insert = BulkInsert::Worker.new(
      Testing.connection,
      Testing.table_name,
      %w(greeting age happy color created_at updated_at))
    @now = Time.now
  end

  test "empty insert is not pending" do
    assert_equal false, @insert.pending?
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
    assert_operator record.created_at, :>=, now
    assert_operator record.updated_at, :>=, now
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

    yo = Testing.find_by(greeting: 'Yo')
    hello = Testing.find_by(greeting: 'Hello')

    assert_not_nil yo
    assert_equal 15, yo.age
    assert_equal false, yo.happy?

    assert_not_nil hello
    assert_equal 25, hello.age
    assert_equal true, hello.happy?
  end
end

