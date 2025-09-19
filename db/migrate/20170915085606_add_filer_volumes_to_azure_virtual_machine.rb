class AddFilerVolumesToAzureVirtualMachine < ActiveRecord::Migration[5.1]
  def change
    add_column :azure_virtual_machines, :filer_volumes, :json, default: {}
  end
end
