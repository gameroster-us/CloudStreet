class AddMachineImageColumnToTask < ActiveRecord::Migration[5.1]
  def change
    add_column :tasks, :machine_image_ids, :string, array: true, default: []
  end
end
