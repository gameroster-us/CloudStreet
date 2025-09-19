class CreateNetAppInstanceFilers < ActiveRecord::Migration[5.1]
  def change
    create_table :instance_filers, id: :uuid do |t|
      t.string :name
      t.string :svm_name
      t.boolean :root_volume, default: false
      t.string :state
      t.string :provider_volume_type
      t.json :data
      t.uuid :filer_id, index: true
      t.uuid :cloud_resource_adapter_id, index: true
      t.uuid :account_id, index: true

      t.timestamps
    end
  end
end
