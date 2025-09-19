class CreateEnvironmentCSService < ActiveRecord::Migration[5.1]
  def change
    create_table :environment_CS_services do |t|
      t.uuid :environment_id, index: true
      t.uuid :CS_service_id, index: true
    end
    add_index :environment_CS_services, :environment_id, :name => 'index_env_CS_services_on_environment_id_and_CS_service_id'
    add_index :environment_CS_services, [:environment_id, :CS_service_id], :name => 'index_env_CS_services_on_env_id_and_CS_service_id'
  end
end
