class AddDefaultValue < ActiveRecord::Migration
  def change
    add_column :testings, :color, :string, default: "chartreuse"
  end
end
