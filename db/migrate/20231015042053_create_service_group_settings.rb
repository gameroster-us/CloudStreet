class CreateServiceGroupSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :service_group_settings, id: :uuid do |t|
      t.uuid :adapter_id
      t.string :whitelisted_tag_keys, array: true, default: []
    end
  end
end
