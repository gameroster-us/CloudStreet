class CreateCloudResourceAdapters < ActiveRecord::Migration[5.1]
  def change
    create_table :cloud_resource_adapters, id: :uuid do |t|
      t.string :name
      t.string :endpoint
      t.json :credentials
      t.uuid :account_id
      t.string :type
      t.timestamps
    end
  end
end
