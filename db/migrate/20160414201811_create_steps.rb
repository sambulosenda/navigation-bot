class CreateSteps < ActiveRecord::Migration
  def change
    create_table :steps do |t|
      t.string :sender_id
      t.float :start_lat
      t.float :start_lng
      t.float :end_lat
      t.float :end_lng
      t.string :distance_text
      t.string :duration_text
      t.string :html_instructions
      t.string :travel_mode

      t.timestamps null: false
    end
  end
end
