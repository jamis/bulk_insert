require 'test_helper'

if ENV['ADAPTER'] == 'PostgreSQL'
  def mocked_worker(ignore: false, update_duplicates: false, return_primary_keys: false, adapter_name: nil)
    BulkInsert::Worker.new(
      Testing.connection,
      Testing.table_name,
      'id',
      %w(greeting age happy created_at updated_at color),
      500, # batch size
      ignore, # ignore
      update_duplicates, # update_duplicates
      return_primary_keys # return_primary_keys
    ).tap { |w| w.adapter_name = adapter_name if adapter_name }
  end

  class BulkInsertWorkerTest < ActiveSupport::TestCase
    setup do
      @insert = mocked_worker
      @now = Time.now
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
      assert_operator record.created_at, :>=, now
      assert_operator record.updated_at, :>=, now
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

      yo = Testing.find_by(greeting: 'Yo')
      hello = Testing.find_by(greeting: 'Hello')

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

      yo = Testing.find_by(greeting: 'Yo')
      hello = Testing.find_by(greeting: 'Hello')

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

      yo = Testing.find_by(greeting: 'Yo')
      hello = Testing.find_by(greeting: 'Hello')

      assert_nil yo
      assert_nil hello
    end

    # Adapter depented methods

    test "adapter dependent postgresql methods" do
      pgsql_worker = mocked_worker(ignore: true, return_primary_keys: true)
      pgsql_worker.add ["Yo", 15, false, nil, nil]

      assert_equal pgsql_worker.compose_insert_query, "INSERT  INTO \"testings\" (\"greeting\",\"age\",\"happy\",\"created_at\",\"updated_at\",\"color\") VALUES ('Yo',15,FALSE,NULL,NULL,'chartreuse') ON CONFLICT DO NOTHING RETURNING id"
    end

    test "primary_key_return_statement returns primary keys on supported adapter (PostgreSQL)" do
      assert_equal(
        mocked_worker(adapter_name: 'PostgreSQL', return_primary_keys: true).primary_key_return_statement,
        ' RETURNING id'
      )
    end
  end
end