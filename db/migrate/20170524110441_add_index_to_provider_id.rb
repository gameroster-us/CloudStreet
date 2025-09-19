class AddIndexToProviderId < ActiveRecord::Migration[5.1]
  def change
  	add_index :aws_records, :provider_id
  end
end
