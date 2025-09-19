class AddAdapterIdToIamRole < ActiveRecord::Migration[5.1]
  def change
  	add_column :aws_iam_roles, :adapter_id, :uuid 
  end
end
