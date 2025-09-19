namespace :rds_configuration do
  desc "Create Default Association for Rds Restriction and NC for Aurora DB"
  task create: :environment do
    Account.all.each do |account|
      if account.rds_configuration.nil?
        account.build_rds_configuration(data: {"postgres"=>{"-1"=>[]}, "mysql"=>{"-1"=>[]}, "sqlserver_ee"=>{"-1"=>[]}, "sqlserver_ex"=>{"-1"=>[]}, "sqlserver_se"=>{"-1"=>[]}, "sqlserver_web"=>{"-1"=>[]}, "oracle_se1"=>{"-1"=>[]}, "oracle_se"=>{"-1"=>[]}, "oracle_ee"=>{"-1"=>[]}, "aurora"=>{"-1"=>[]}}, updated_by: User.first, created_by: User.first)
        account.save
      elsif account.rds_configuration.data['aurora'].nil?
        account.rds_configuration.data.merge!("aurora"=>{"-1"=>[]})
        account.rds_configuration.data_will_change!
        account.rds_configuration.save!         
      end
      unless account.service_naming_defaults.rds.where(service_type: 'Aurora - compatible with MySQL 5.6.10a').present?
        account.service_naming_defaults.build(prefix_service_name: "auroradb##",  suffix_service_count: 2, last_used_number: "0",service_type: "Aurora - compatible with MySQL 5.6.10a", generic_service_type: "Rds", sub_service_type: 'aurora', free_text: false )
        account.save!
      end
    end
  end
end