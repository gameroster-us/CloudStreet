class AddIndexToTables < ActiveRecord::Migration[5.2]
  def change
    add_index :vpcs, [:adapter_id, :state]
    add_index :snapshots, [:image_reference]
    add_index :regions, [:region_name]
    add_index :regions, [:code]
    add_index :template_costs, [:region_id]
    add_index :connections, [:interface_id, :remote_interface_id]
    add_index :azure_rate_cards, [:id, :subscription_id]
    add_index :account_regions, [:account_id, :region_id]
    add_index :regions, [:adapter_id]
    add_index :user_roles_users, [:user_role_id]
    add_index :user_roles_users, [:user_role_id, :user_id]
    add_index :aws_records, [:provider_id, :account_id, :adapter_id, :region_id], name: 'aws_records_pid_aid_rid'
    add_index :sa_recommendations, [:tenant_id, :adapter_id, :provider_id], name: 'sa_recommendations_tid_aid_pid'
    change_column :account_gcp_multi_regions, :enabled, :boolean, default: true
  end
end
