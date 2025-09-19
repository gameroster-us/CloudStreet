class ChangeTypeColumnInSoeScripts < ActiveRecord::Migration[5.1]
  def change
    rename_column :soe_scripts, :type, :script_type
    remove_column :soe_scripts_groups, :sourceable_id, :uuid
    add_column :soe_scripts_groups, :sourceable_id, :uuid
  end
end
