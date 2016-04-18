class CreateSenders < ActiveRecord::Migration
  def change
    create_table :senders do |t|
      t.string :facebook_id
      t.integer :navigation_status
      t.string :current_step_id

      t.timestamps null: false
    end
  end
end
