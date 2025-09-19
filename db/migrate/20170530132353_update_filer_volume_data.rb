class UpdateFilerVolumeData < ActiveRecord::Migration[5.1]
  def up
    FilerVolume.all.each do|vol|
      vol.update(
        size_info: vol.data["size"], 
        export_policy_info: vol.data["export_policy_info"].transform_keys{|k| k.underscore.downcase }.slice("policy_type","ips"),
        snapshot_policy: vol.data["snapshot_policy"],
        thin_provisioning: vol.data["thin_provisioning"],
        deduplication: vol.data["deduplication"],
        compression: vol.data["compression"],
        aggregate_name: vol.data["aggregate_name"]
      )
    end

    def down
      CSLogger.info "#{caller[0]}"
      CSLogger.info "Synchronize filers to update filer volumes data"
    end
  end
end
