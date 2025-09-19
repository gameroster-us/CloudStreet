class CreateStorageVms < ActiveRecord::Migration[5.1]
  def change
    create_table :storage_vms, id: :uuid  do |t|
      t.uuid :filer_id, index: true
      t.string :name
      t.string :state
      t.string :language
      t.text :allowed_aggregates, array: true, default: []

      t.timestamps
    end
  end
end
