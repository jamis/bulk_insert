# BulkInsert

A little ActiveRecord extension for helping to insert lots of rows in a
single insert statement.

## Installation

Add it to your Gemfile:

    gem 'bulk_insert'

## Usage

BulkInsert adds a new class method to your ActiveRecord models:

    class Book < ActiveRecord::Base
    end

    book_attrs = ... # some array of hashes, for instance
    Book.bulk_insert do |worker|
      book_attrs.each do |attrs|
        worker.add(attrs)
      end
    end

All of those `#add` calls will be accumulated into a single SQL insert
statement, vastly improving the performance of multiple sequential
inserts (think data imports and the like).

By default, the columns to be inserted will be all columns in the table,
minus the `id` column, but if you want, you can explicitly enumerate
the columns:

    Book.bulk_insert(:title, :author) do |worker|
      # specify a row as an array of values...
      worker.add ["Eye of the World", "Robert Jordan"]

      # or as a hash
      worker.add title: "Lord of Light", author: "Roger Zelazny"
    end

It will automatically set created_at/updated_at columns to the current
date, as well.

    Book.bulk_insert(:title, :author, :created_at, :updated_at) do |worker|
      # specify created_at/updated_at explicitly...
      worker.add ["The Chosen", "Chaim Potok", Time.now, Time.now]

      # or let BulkInsert set them by default...
      worker.add ["Hello Ruby", "Linda Liukas"]
    end

By default, the batch is always saved when the block finishes, but you
can explicitly save inside the block whenever you want, by calling
`#save!` on the worker:

    Book.bulk_insert do |worker|
      worker.add(...)
      worker.add(...)

      worker.save!

      worker.add(...)
      #...
    end

That will save the batch as it has been defined to that point, and then
empty the batch so that you can add more rows to it if you want.


### Batch Set Size

By default, the size of the insert is limited to 500 rows at a time.
This is called the _set size_. If you add another row that causes the
set to exceed the set size, the insert statement is automatically built
and executed, and the batch is reset.

If you want a larger (or smaller) set size, you can specify it in
two ways:

    # specify set_size when initializing the bulk insert...
    Book.bulk_insert(set_size: 100) do |worker|
      # ...
    end

    # specify it on the worker directly...
    Book.bulk_insert do |worker|
      worker.set_size = 100
      # ...
    end


## License

BulkInsert is released under the MIT license (see MIT-LICENSE) by
Jamis Buck (jamis@jamisbuck.org).
