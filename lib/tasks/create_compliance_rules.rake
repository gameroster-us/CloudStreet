namespace :compliance_rules do
  desc "Create compliance rules"
  task create_compliance_rules_cis: :environment do
  	ComplianceRulesWorker.perform_async('CIS')
  end
  task create_compliance_rules_pci: :environment do
  	ComplianceRulesWorker.perform_async('PCI')
  end
  task create_compliance_rules_nist: :environment do
  	ComplianceRulesWorker.perform_async('NIST')
  end
  task create_compliance_rules_hipaa: :environment do
    ComplianceRulesWorker.perform_async('HIPAA')
  end
  task create_compliance_rules_awswa: :environment do
    ComplianceRulesWorker.perform_async('AWSWA')
  end
end