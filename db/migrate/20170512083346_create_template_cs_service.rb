class CreateTemplateCSService < ActiveRecord::Migration[5.1]
  def change
    create_table :template_CS_services, id: :uuid do |t|
      t.uuid :template_id, index: true
      t.uuid :CS_service_id, index: true    
    end
    add_index :template_CS_services, [:template_id, :CS_service_id], :unique => true
    add_index :template_CS_services, :template_id
  end
end
