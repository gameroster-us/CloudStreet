class SecurityScanners::ScannerObjects::Volume < Struct.new(:id, :name, :state, :tags,:server_id, :snapshot_id , :encrypted, :snapshot_publicly_accessible, :public_snapshot_names, :ebs_snapshot_encryption, :non_encrypted_snapshot_names, :volumes_attached_with_stopped_ec2, :ebs_volumes_recent_snapshot)
  extend SecurityScanners::ScannerObjects::ObjectParser
  
  def scan(rule_sets, &block)
    rule_sets.each do |rule|
      status = eval(rule["evaluation_condition"])
      yield(rule) if status
    end
  end

  class << self
    def create_new(object)
      data_attr = !object.provider_data.blank? ? "parsed_provider_data" : "parsed_data"
      encrypted = object.send(data_attr).try(:[], 'encrypted')
      # Remove N+1 queries here
      vol = object.snapshots.active_snapshots
      snapshot_publicly_accessible = vol.any? {|vols| vols.publicly_accessible }
      public_snapshot_names = vol.select {|s| s if s.publicly_accessible }.pluck(:name).compact
      ebs_snapshot_encryption = vol.count.zero? ? nil : vol.any? { |s| s.send(data_attr)["encrypted"] rescue false }
      non_encrypted_snapshot_names = vol.select {|s| s unless s.send(data_attr)["encrypted"]}.pluck(:name).compact
      return new(
        object.send(data_attr)["id"],
        object.name,
        object.send(data_attr)["state"],
        object.tags,
        object.server_id,
        object.provider_data['snapshot_id'],
        encrypted,
        snapshot_publicly_accessible,
        public_snapshot_names,
        ebs_snapshot_encryption,
        non_encrypted_snapshot_names,
        false,
        false,
       )
    end

  end  
end
