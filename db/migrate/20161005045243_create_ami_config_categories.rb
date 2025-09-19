class CreateAmiConfigCategories < ActiveRecord::Migration[5.1]
  def change
    create_table :ami_config_categories, id: :uuid  do |t|
      t.string :name, null: false
      t.uuid :account_id, index: true
      t.timestamps
    end
  end
end
