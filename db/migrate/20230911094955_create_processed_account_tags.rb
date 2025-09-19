class CreateProcessedAccountTags < ActiveRecord::Migration[5.2]
  def change
    create_table :processed_account_tags, id: :uuid do |t|
      t.text :account_tags, array: true, default: []
      t.string :adapter_id

      t.timestamps
    end
  end
end
