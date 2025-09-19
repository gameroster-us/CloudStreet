namespace :feature_flags do

  # rake feature_flags:create

  desc 'create feature flags from feature.yml file'
  task create: :environment do
    puts '------- Create Feature Flags Process Start -------'
    db_records = Flipper.features.map(&:key)
    yml_records = FeatureFlag.all
    remaining_records = yml_records - db_records
    remaining_records.each do |feature_name|
      puts "======== Inserting feature :: #{feature_name} ========"
      Flipper.add(feature_name)
    end
    puts '------- Create Feature Flags Process END -------'
  end
end
