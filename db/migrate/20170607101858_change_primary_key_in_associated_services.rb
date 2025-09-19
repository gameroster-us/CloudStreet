class ChangePrimaryKeyInAssociatedServices < ActiveRecord::Migration[5.1]
  def change
    remove_column :associated_services, :id
    execute %Q{ ALTER TABLE "associated_services" ADD PRIMARY KEY ("CS_service_id", "associated_CS_service_id"); }
  end
end
