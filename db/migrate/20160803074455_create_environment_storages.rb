class CreateEnvironmentStorages < ActiveRecord::Migration[5.1]
  def change
    create_table :environment_storages do |t|
      t.uuid :storage_id
      t.uuid :environment_id
    end
  end
end
