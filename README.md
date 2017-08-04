# BulkInsert

A little ActiveRecord extension for helping to insert lots of rows in a
single insert statement.

## Installation

Add it to your Gemfile:

```ruby
gem 'bulk_insert'
```

## Usage

BulkInsert adds a new class method to your ActiveRecord models:

```ruby
class Book < ActiveRecord::Base
end

book_attrs = ... # some array of hashes, for instance
Book.bulk_insert do |worker|
  book_attrs.each do |attrs|
    worker.add(attrs)
  end
end
```

All of those `#add` calls will be accumulated into a single SQL insert
statement, vastly improving the performance of multiple sequential
inserts (think data imports and the like).

If you don't like using a block API, you can also simply pass an array
of rows to be inserted:

```ruby
book_attrs = ... # some array of hashes, for instance
Book.bulk_insert values: book_attrs
```

By default, the columns to be inserted will be all columns in the table,
minus the `id` column, but if you want, you can explicitly enumerate
the columns:

```ruby
Book.bulk_insert(:title, :author) do |worker|
  # specify a row as an array of values...
  worker.add ["Eye of the World", "Robert Jordan"]

  # or as a hash
  worker.add title: "Lord of Light", author: "Roger Zelazny"
end
```

It will automatically set `created_at`/`updated_at` columns to the current
date, as well.

```ruby
Book.bulk_insert(:title, :author, :created_at, :updated_at) do |worker|
  # specify created_at/updated_at explicitly...
  worker.add ["The Chosen", "Chaim Potok", Time.now, Time.now]

  # or let BulkInsert set them by default...
  worker.add ["Hello Ruby", "Linda Liukas"]
end
```

Similarly, if a value is omitted, BulkInsert will use whatever default
value is defined for that column in the database:

```ruby
# create_table :books do |t|
#   ...
#   t.string "medium", default: "paper"
#   ...
# end

Book.bulk_insert(:title, :author, :medium) do |worker|
  worker.add title: "Ender's Game", author: "Orson Scott Card"
end

Book.first.medium #-> "paper"
```

By default, the batch is always saved when the block finishes, but you
can explicitly save inside the block whenever you want, by calling
`#save!` on the worker:

```ruby
Book.bulk_insert do |worker|
  worker.add(...)
  worker.add(...)

  worker.save!

  worker.add(...)
  #...
end
```

That will save the batch as it has been defined to that point, and then
empty the batch so that you can add more rows to it if you want. Note
that all records saved together will have the same created_at/updated_at
timestamp (unless one was explicitly set).


### Batch Set Size

By default, the size of the insert is limited to 500 rows at a time.
This is called the _set size_. If you add another row that causes the
set to exceed the set size, the insert statement is automatically built
and executed, and the batch is reset.

If you want a larger (or smaller) set size, you can specify it in
two ways:

```ruby
# specify set_size when initializing the bulk insert...
Book.bulk_insert(set_size: 100) do |worker|
  # ...
end

# specify it on the worker directly...
Book.bulk_insert do |worker|
  worker.set_size = 100
  # ...
end
```

### Insert Ignore

By default, when an insert fails the whole batch of inserts fail. The
_ignore_ option ignores the inserts that would have failed (because of
duplicate keys or a null in column with a not null constraint) and
inserts the rest of the batch.

This is not the default because no errors are raised for the bad
inserts in the batch.

```ruby
destination_columns = [:title, :author]

# Ignore bad inserts in the batch
Book.bulk_insert(*destination_columns, ignore: true) do |worker|
  worker.add(...)
  worker.add(...)
  # ...
end
```

### Update Duplicates (MySQL)

If you don't want to ignore duplicate rows but instead want to update them
then you can use the _update_duplicates_ option. Set this option to true
and when a duplicate row is found the row will be updated with your new
values. Default value for this option is false.

```ruby
destination_columns = [:title, :author]

# Update duplicate rows
Book.bulk_insert(*destination_columns, update_duplicates: true) do |worker|
  worker.add(...)
  worker.add(...)
  # ...
end
```


## License

BulkInsert is released under the MIT license (see MIT-LICENSE) by
Jamis Buck (jamis@jamisbuck.org).
