class AddErrorToFilerVolumes < ActiveRecord::Migration[5.1]
  def up
    add_column :filer_volumes, :error_message, :text
    add_column :filer_volumes, :export_policy_info, :json, default: {policy_type: "none", ips: [] }
    add_column :filer_volumes, :snapshot_policy, :text, default: "none"
    add_column :filer_volumes, :size_info, :json, default: {size: 1, unit: "GB"}
    add_column :filer_volumes, :thin_provisioning, :boolean, default: false
    add_column :filer_volumes, :deduplication, :boolean, default: false
    add_column :filer_volumes, :compression, :boolean, default: false
    add_column :filer_volumes, :aggregate_name, :text
    add_column :filer_volumes, :share_name, :text
  end

  def down
    remove_column :filer_volumes, :share_name
    remove_column :filer_volumes, :error_message
    remove_column :filer_volumes, :export_policy_info
    remove_column :filer_volumes, :snapshot_policy
    remove_column :filer_volumes, :size_info
    remove_column :filer_volumes, :thin_provisioning
    remove_column :filer_volumes, :deduplication
    remove_column :filer_volumes, :compression
    remove_column :filer_volumes, :aggregate_name
  end  
end
