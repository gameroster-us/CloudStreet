namespace :reseller_report_profile do
  desc "Creation report profile for resellers"
  task create: :environment do
    CSLogger.info "============Data Creation Is Starting!!=============="
    begin 
      Organisation.where(parent_id: nil, organisation_purpose: 'distributor').where.not(subdomain: nil, user_id: nil).each do |parent|
        CurrentAccount.client_db = parent.account
       	next if CurrentAccount.client_db.eql?('default')

        parent.child_organisations.where(organisation_purpose: "reseller").each do |reseller|
          next unless reseller.report_profile.present?
          CSLogger.info "Creating Reseller Report Profile for #{reseller.subdomain}"

          ReportProfile::Helper.create_reseller_report_profiles(reseller)
        end
      end
    rescue Exception => e
      CSLogger.error"============#{e.inspect}========="
    end
  end 
end
      

