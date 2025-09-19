class CreateGeneralSettings < ActiveRecord::Migration[5.1]
  def change
    create_table :general_settings, id: :uuid do |t|
      t.boolean :naming_convention_enabled, default: false
      t.uuid :account_id

      t.timestamps
    end
  end
end
