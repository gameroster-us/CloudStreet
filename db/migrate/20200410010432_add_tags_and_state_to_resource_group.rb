class AddTagsAndStateToResourceGroup < ActiveRecord::Migration[5.1]
  def change
    add_column :azure_resource_groups, :tags, :json, array: true, default: []
    add_column :azure_resource_groups, :state, :string
  end
end
