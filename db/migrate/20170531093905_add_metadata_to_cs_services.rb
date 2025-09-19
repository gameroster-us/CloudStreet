class AddMetadataToCSServices < ActiveRecord::Migration[5.1]
  def change
    add_column :CS_services, :metadata, :json, default: {}
  end
end
