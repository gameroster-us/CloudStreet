class AddFieldsToIamGroup < ActiveRecord::Migration[5.1]
  def change
  	add_column :iam_groups, :list_group_policies, :json 
  end
end
