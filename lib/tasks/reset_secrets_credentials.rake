require "./lib/marketplace/models/organisation_detail"
namespace :reset_credentials do
  desc 'Reset the credentials of config/secrets.yml from the adapter set via the appliances'
  task secrets: :environment do
    begin
      CSLogger.info("Task to reset config/secrets.yml #{Time.now}")
      s3_config = OrganisationDetail.first.s3_config
      return if s3_config.blank?
      adapter = Adapter.find(s3_config["adapter_id"])
      region = Region.find(s3_config["bucket_region_id"])
      adapter.connection_s3
      template_base_url = region.code.eql?("us-east-1") ? "https://s3.amazonaws.com/" : "https://s3-#{region.code}.amazonaws.com/"
      template_base_url = template_base_url.gsub('/','\\\\\/')
      adapter_access_key_id = adapter.access_key_id.gsub('/','\\\\\/')
      adapter_secret_access_key = adapter.secret_access_key.gsub('/','\\\\\/')
      system("bash #{ENV['APP_ROOT']}/script/marketplace_vars_setter.sh #{s3_config["bucket_id"]} #{template_base_url} #{region.code} #{adapter_access_key_id} #{adapter_secret_access_key}")
      CSLogger.info("Completed setting config/secrets.yml #{Time.now}")
    rescue Exception => e
      CSLogger.error("Error resetting the values of config/secrets.yml @ #{Time.now}")
      CSLogger.error("#{e.class} #{e.message} #{e.backtrace}")
    end
  end
end
