class CreateResourceGroups < ActiveRecord::Migration[5.1]
  def change
    create_table :resource_groups, id: :uuid do |t|
      t.string :name
      t.string :location
      t.json :tags
      t.json :data
      t.json :provider_data
      t.string :type
      t.uuid :subscription_id, index: true

      t.timestamps
    end
  end
end
