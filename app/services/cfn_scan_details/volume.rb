class CFNScanDetails::Volume

  class << self

    def ebs_encrypted(res)
      {
        "resource": "Volume",
        "attributes": {
          "risk-level": "HIGH",
          "message": "EBS Encrypted",
          "description": "Ensure that existing Elastic Block Store (EBS) attached volumes are encrypted to meet security and compliance requirements.",
          "categories": [
            "Security"
          ]
        }
      }
    end

    def ebs_encrypted_with_kms_key(res)
      {
        "resource": "Volume",
        "attributes": {
          "risk-level": "HIGH",
          "message": "EBS Encrypted With KMS Customer Master Keys",
          "description": "Ensure EBS volumes are encrypted with KMS CMKs in order to have full control over data encryption and decryption.",
          "categories": [
            "Security"
          ]
        }
      }
    end

  end

end
