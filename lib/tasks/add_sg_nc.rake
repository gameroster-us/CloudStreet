namespace :add_sg_nc do
  desc "Adding security group to naming conventions"
  task add: :environment do
    accounts = Account.all
    accounts.each do |account|
      CSLogger.info "----------addding default security group service naming conventions---------------"
      account.create_general_setting  unless account.general_setting.present?
      # CommonConstants::SERVICE_NAMING_MAP['generic_service_map']['Security Group'].each do |key, val|
      account.service_naming_defaults.build(
        service_type: 'Security Group',
        prefix_service_name: 'security-group',
        suffix_service_count: 2,
        last_used_number: 0,
        generic_service_type: 'SecurityGroup',
        sub_service_type: 'security-group'
      )
      account.save
      CSLogger.info "----------adding default security group service naming conventions------completed---------------"
    end
  end
end
