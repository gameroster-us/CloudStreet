class RemoveDeadFieldsFromVm < ActiveRecord::Migration[5.1]
  def change
    remove_column :azure_virtual_machines, :image_reference, :json if column_exists? :azure_virtual_machines, :image_reference
    remove_column :azure_virtual_machines, :hardware_profile, :json if column_exists? :azure_virtual_machines, :hardware_profile
    remove_column :azure_virtual_machines, :network_profile, :json if column_exists? :azure_virtual_machines, :network_profile
  end
end
