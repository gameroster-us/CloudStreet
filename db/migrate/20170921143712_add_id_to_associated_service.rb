class AddIdToAssociatedService < ActiveRecord::Migration[5.1]
  def change
    add_column :associated_services, :id, :uuid, :default => "uuid_generate_v4()"
  end
end
