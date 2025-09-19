class CreateMachineImageConfigurationsSoeScripts < ActiveRecord::Migration[5.1]
  def change
  	add_column :machine_image_configurations, :rundata , :text
    create_table :machine_image_configurations_soe_scripts, :id => :uuid do |t|
      t.uuid :machine_image_configuration_id
      t.uuid :soe_script_id
      t.string :soe_script_type
      t.index [:machine_image_configuration_id, :soe_script_id, :soe_script_type],:unique=>true,:name=>"index_config_scripts_on_ami_conf_id_and_soe_script_id"
    end
  end
end
