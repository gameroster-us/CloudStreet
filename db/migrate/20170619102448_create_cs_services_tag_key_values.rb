class CreateCSServicesTagKeyValues < ActiveRecord::Migration[5.1]
  def change
    create_table :CS_services_tag_key_values, id: :uuid do |t|
      t.uuid :CS_service_id
      t.uuid :tag_key_value_id
    end
    add_index :CS_services_tag_key_values, :CS_service_id
    add_index :CS_services_tag_key_values, [:CS_service_id, :tag_key_value_id], :unique => true, :name => 'CS_service_tags_unique_on_CS_service_id_tag_key_value_id'
  end
end
