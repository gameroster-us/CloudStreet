namespace :update do
  # one time rake task to add new columns
  desc 'Update account_group_athena_table for new column/data'
  task account_group_athena_table: :environment do
    Organisation.active.each do |org|
      ['GCP'].each do |type|
        AthenaAccountGroupTableUpdateWorker.perform_async(org.organisation_identifier, type)
      end
    end
  end
end
