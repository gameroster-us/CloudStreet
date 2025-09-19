namespace :deleteservices do
  desc "Delete acount specific services from db"
  task seed: :environment do
    TESTDATA = YAML.load_file(Rails.root.join('data', 'testdata.yml'))
    TESTDATA.each do |key, users|
      organisation = Organisation.find_by_name(key)
      account = Account.find_by_organisation_id(organisation.id)
      delete_services(account.id)
    end        
  end 
  def delete_services(account_id)
    id = account_id

    CostSummary.where(account_id: id).destroy_all
    Cost.where(account_id: id).destroy_all
    Snapshot.where(account_id: id).destroy_all
    Resource.where(account_id: id).destroy_all

    Service::ServiceDeleter.remove_services_with_all_relations!(Service.where(account_id: id).all)

    Environment.where(account_id: id).each do|e|
      e.services.each do |s|
        s.interfaces.each do|interface|
          interface.connections.destroy_all
        end
      end
      e.services.each { |s| s.interfaces.destroy_all }
      e.services.destroy_all
      e.destroy
    end

    Application.where(account_id: id).destroy_all

    Template.where(account_id: id).each do|t|
      t.services.each do |s|
        s.interfaces.each do|interface|
          interface.connections.destroy_all
        end
      end
      t.services.each do |s|
        s.interfaces.destroy_all
      end
      t.services.destroy_all
      t.destroy
    end


    Tag.where(account_id: id).destroy_all
    Event.where(account_id: id).destroy_all
    SecurityGroup.where(account_id: id).destroy_all
    RouteTable.where(account_id: id).destroy_all
    InternetGateway.where(account_id: id).destroy_all
    Vpc.where(account_id: id).destroy_all
    AWSRecord.where(account_id: id).destroy_all
    Alert.where(alertable_type: "Account",alertable_id: id).destroy_all
    Synchronization.where(account_id: id).destroy_all
    ServiceSynchronizationHistory.where(account_id: id).destroy_all
    OrganisationImage.where(account_id: id).destroy_all
  end
end