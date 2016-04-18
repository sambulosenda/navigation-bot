class CreateImages < ActiveRecord::Migration
  def change
    create_table :images do |t|
      t.string :step_id
      t.string :name
      t.string :uri
      t.integer :width
      t.integer :height

      t.timestamps null: false
    end
  end
end
