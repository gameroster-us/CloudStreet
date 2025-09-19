class CreateJoinTableEnvironmentFilerVolumes < ActiveRecord::Migration[5.1]
  def change
    create_table :environment_filer_volumes, id: :uuid do |t|
      t.uuid :environment_id
      t.uuid :filer_volume_id
    end
    add_index :environment_filer_volumes, [:environment_id, :filer_volume_id], name: "env_filer_volumes_on_environment_id_and_filer_volume_id"
    add_index :environment_filer_volumes, [:filer_volume_id, :environment_id], name: "env_filer_volumes_on_filer_volume_id_and_environment_id"
  end
end
