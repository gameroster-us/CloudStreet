class CreateApplicationTable < ActiveRecord::Migration[5.1]
  def change
    create_table :applications, id: :uuid do |t|
      t.string :name
      t.text :description
      t.uuid :account_id, index: true
      t.uuid :created_by_user_id, index: true
      t.uuid :updated_by_user_id, index: true
      t.timestamps
    end
  end
end
