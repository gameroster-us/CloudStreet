class AddAccessToFilerVolumes < ActiveRecord::Migration[5.1]
  def self.up
    add_column :filer_volumes, :access, :json
      execute ""\
      "DELETE FROM environment_filer_volumes WHERE environment_filer_volumes.filer_volume_id IN (SELECT environment_filer_volumes.filer_volume_id FROM environment_filer_volumes left outer join filer_volumes on environment_filer_volumes.filer_volume_id = filer_volumes.id);"\
      "DELETE FROM instance_filer_volumes WHERE instance_filer_volumes.filer_volume_id IN (SELECT instance_filer_volumes.filer_volume_id FROM instance_filer_volumes left outer join filer_volumes on instance_filer_volumes.filer_volume_id = filer_volumes.id);"\
      "DELETE FROM environment_filer_volumes WHERE environment_filer_volumes.environment_id IN (SELECT environment_filer_volumes.environment_id FROM environment_filer_volumes left outer join environments on environment_filer_volumes.environment_id = environments.id);"\
      "DELETE FROM instance_filer_volumes WHERE instance_filer_volumes.service_id IN (SELECT instance_filer_volumes.service_id FROM instance_filer_volumes left outer join services on instance_filer_volumes.service_id = services.id);"\
      "ALTER TABLE environment_filer_volumes DROP CONSTRAINT IF EXISTS delete_env_filer_volumes_on_env, ADD CONSTRAINT delete_env_filer_volumes_on_env FOREIGN KEY (environment_id) REFERENCES environments (id) ON DELETE CASCADE;"\
      "ALTER TABLE instance_filer_volumes DROP CONSTRAINT IF EXISTS delete_instance_filer_volumes_on_svc, ADD CONSTRAINT delete_instance_filer_volumes_on_svc FOREIGN KEY (service_id) REFERENCES services (id) ON DELETE CASCADE;"\
      "ALTER TABLE environment_filer_volumes DROP CONSTRAINT IF EXISTS delete_env_filer_volumes_on_vol, ADD CONSTRAINT delete_env_filer_volumes_on_vol FOREIGN KEY (filer_volume_id) REFERENCES filer_volumes (id) ON DELETE CASCADE;"\
      "ALTER TABLE instance_filer_volumes DROP CONSTRAINT IF EXISTS delete_instance_filer_volumes_on_fvol, ADD CONSTRAINT delete_instance_filer_volumes_on_fvol FOREIGN KEY (filer_volume_id) REFERENCES filer_volumes (id) ON DELETE CASCADE;"
  end

  def self.down
    remove_column :filer_volumes, :access
    execute "ALTER TABLE environment_filer_volumes DROP CONSTRAINT IF EXISTS delete_env_filer_volumes_on_env;"\
      "ALTER TABLE instance_filer_volumes DROP CONSTRAINT IF EXISTS delete_instance_filer_volumes_on_svc;"\
      "ALTER TABLE environment_filer_volumes DROP CONSTRAINT IF EXISTS delete_env_filer_volumes_on_vol;"\
      "ALTER TABLE instance_filer_volumes DROP CONSTRAINT IF EXISTS delete_instance_filer_volumes_on_fvol;"
  end
end
