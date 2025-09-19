# frozen_string_literal: false

# rake office365_services:populate_office365_services
namespace :office365_services do
  task populate_office365_services: :environment do
    CloudStreet.log 'Started Populating Azure Office 365 Services'
    Azure::PopulateOffice365ServicesWorker.perform_async
  end
end
