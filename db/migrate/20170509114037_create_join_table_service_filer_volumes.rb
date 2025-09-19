class CreateJoinTableServiceFilerVolumes < ActiveRecord::Migration[5.1]
  def change
    create_table :instance_filer_volumes, id: :uuid do |t|
      t.uuid :service_id
      t.uuid :filer_volume_id
    end
    add_index :instance_filer_volumes, [:service_id, :filer_volume_id]
    add_index :instance_filer_volumes, [:filer_volume_id, :service_id]
  end
end
