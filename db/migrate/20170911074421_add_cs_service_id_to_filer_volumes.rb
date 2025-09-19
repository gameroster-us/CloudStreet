class AddCSServiceIdToFilerVolumes < ActiveRecord::Migration[5.1]
  def change
    add_column :filer_volumes, :CS_service_id, :uuid
  end
end
