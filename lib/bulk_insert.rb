require 'bulk_insert/worker'

module BulkInsert
  extend ActiveSupport::Concern

  class_methods do
    def bulk_insert(*columns, set_size:500)
      columns = default_bulk_columns if columns.empty?
      worker = BulkInsert::Worker.new(connection, table_name, columns, set_size)

      if block_given?
        transaction do
          yield worker
          worker.save!
        end
        self
      else
        worker
      end
    end

    # helper method for preparing the columns before a call to :bulk_insert
    def default_bulk_columns
      self.column_names - %w(id)
    end

  end
end

ActiveRecord::Base.send :include, BulkInsert
