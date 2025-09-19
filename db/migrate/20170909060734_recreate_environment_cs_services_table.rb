class RecreateEnvironmentCSServicesTable < ActiveRecord::Migration[5.1]
  def change
    drop_table :environment_CS_services if ActiveRecord::Base.connection.table_exists? :environment_CS_services
    create_table :environment_CS_services, id: :uuid do |t|
      t.uuid :environment_id, index: true
      t.uuid :CS_service_id, index: true
    end
    add_index :environment_CS_services, :environment_id, :name => 'index_env_CS_services_on_environment_id_and_CS_service_id'

    add_foreign_key(:environment_CS_services, :environments, column: 'environment_id', on_delete: :cascade)
    add_foreign_key(:template_CS_services, :templates, column: 'template_id', on_delete: :cascade)
  end
end
