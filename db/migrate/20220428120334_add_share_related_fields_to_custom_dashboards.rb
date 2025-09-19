class AddShareRelatedFieldsToCustomDashboards < ActiveRecord::Migration[5.1]
  def change
    add_column :custom_dashboards, :shared_with_roles, :string, array: true, default: []
    add_column :custom_dashboards, :shared_with, :string, array: true, default: []
    add_column :custom_dashboards, :shared_at, :hstore
  end
end
