class CreateTestings < ActiveRecord::Migration
  def change
    create_table :testings do |t|
      t.string :greeting
      t.integer :age
      t.boolean :happy

      t.timestamps null: false
    end
  end
end
