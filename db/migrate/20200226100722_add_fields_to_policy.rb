class AddFieldsToPolicy < ActiveRecord::Migration[5.1]
  def change
  	add_column :policies, :adapter_id, :uuid 
  	add_column :policies, :aws_account_id, :string 
  	add_column :policies, :policy_document, :json 
  end
end
