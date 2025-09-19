class AddFkCascadeToMachineImageConfigurationSoeScriptsSeed < ActiveRecord::Migration[5.1]
  def up
  	SoeScripts::RemoteSource.where(state: :errored).update_all(state: :error)
  	MachineImageConfigurationsSoeScript.where.not(machine_image_configuration_id: MachineImageConfiguration.pluck(:id)).delete_all
  	MachineImageConfigurationsSoeScript.where.not(soe_script_id: SoeScript.pluck(:id)).delete_all
  	AccountSoeScriptsRemoteSource.where(account_id: nil).delete_all
  end  
end

