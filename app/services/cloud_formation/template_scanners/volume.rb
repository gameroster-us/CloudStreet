class CloudFormation::TemplateScanners::Volume

  attr_accessor :template_data, :scan_details

  def start_template_scanning(resource)
    check_ebs_encrypted(resource)
    check_ebs_encrypted_with_kms_key(resource)
    template_data
  end

  def check_ebs_encrypted(res)
    template_data << scan_details.ebs_encrypted(res) unless res['Encrypted']
  end

  def check_ebs_encrypted_with_kms_key(res)
    if res['Encrypted'] && res['KmsKeyId'].blank?
      template_data << scan_details.ebs_encrypted_with_kms_key(res)
    end
  end

end
