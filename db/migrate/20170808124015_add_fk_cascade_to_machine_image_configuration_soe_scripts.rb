class AddFkCascadeToMachineImageConfigurationSoeScripts < ActiveRecord::Migration[5.1]
  def change
    add_foreign_key(:machine_image_configurations_soe_scripts, :machine_image_configurations, column: 'machine_image_configuration_id', name: 'fk_rails_miconfsoescript_miconf', on_delete: :cascade)
    add_foreign_key(:machine_image_configurations_soe_scripts, :soe_scripts, column: 'soe_script_id', name: 'fk_rails_miconfsoescript_soe_script', on_delete: :cascade)  	
    
    add_foreign_key(:accounts_soe_scripts_remote_sources, :soe_scripts_remote_sources, column: 'soe_scripts_remote_source_id', name: 'fk_rails_accscriptsource_scriptsource', on_delete: :cascade)
  end
end
