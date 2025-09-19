class CFNScanDetails::EC2Instance

  class << self

    def ec2_monitoring(res)
      {
        "resource": "Instance",
        "attributes": {
          "risk-level": "LOW",
          "message": "EC2 Instance Detailed Monitoring",
          "description": "Ensure that detailed monitoring is enabled for the AWS EC2 instances that you need to monitor closely.",
          "categories": [
            "Performance",
            "Reliability",
            "Operational"
          ]
        }
      }
    end

    def ec2_api_termination(res)
      {
        "resource": "Instance",
        "attributes": {
          "risk-level": "MEDIUM",
          "message": "EC2 Instance Termination Protection",
          "description": "Ensure Termination Protection feature is enabled for EC2 instances that are not part of ASGs.",
          "categories": [
            "Reliability"
          ]
        }
      }
    end

   def ec2_hibernation_options(res)
      {
        "resource": "Instance",
        "attributes": {
          "risk-level": "MEDIUM",
          "message": "Enable AWS EC2 Hibernation",
          "description": "Ensure that Hibernation feature is enabled for EBS-backed EC2 instances to retain memory state across instance stop/start cycles.",
          "categories": [
            "Reliability"
          ]
        }
      }
    end

    def root_volume_encryption(res)
      {
        "resource": "RootVolume",
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

  end

end
