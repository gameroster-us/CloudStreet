namespace :azure_compliance_rules do
  desc "Create azure compliance rules"
  task create_cis_compliance_rules: :environment do
    Azure::ComplianceRulesWorker.perform_async('CIS_V_1.3.0')
  end

  task create_nist_compliance_rules: :environment do
    Azure::ComplianceRulesWorker.perform_async('NIST_V_SP_800_53_Rev.5')
  end
 
  task create_pci_compliance_rules: :environment do
    Azure::ComplianceRulesWorker.perform_async('PCI_V_3.2.1')
  end

  task create_hipaa_compliance_rules: :environment do
    Azure::ComplianceRulesWorker.perform_async('HIPAA_V_9.2')
  end
end