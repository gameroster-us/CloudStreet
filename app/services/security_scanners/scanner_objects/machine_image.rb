class SecurityScanners::ScannerObjects::MachineImage < Struct.new(:id, :name, :state,:tags, :publicly_accessible, :ami_days_old_check, :ami_encryption_id)
  extend SecurityScanners::ScannerObjects::ObjectParser

  def scan(rule_sets, &block)
    rule_sets.each do |rule|
      status = eval(rule["evaluation_condition"])
      yield(rule) if status
    end
  end

  class << self
      def create_new(object)
        bdm = object.block_device_mapping.is_a?(String) ? eval(object.block_device_mapping || "[]") : object.block_device_mapping
        return new(
          object.image_id,
          object.name,
          "active",
          object.service_tags,
          object.is_public.eql?('t') ? true : false,
          object.creation_date.present? ? object.creation_date < (Time.now - 180.days) : false ,
          bdm.blank? ? "false" : bdm.first["encrypted"]
        )
      end
  end

end
