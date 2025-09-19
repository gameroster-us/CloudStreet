class Rightsizings::UploadDataToS3 < ApplicationService

  attr_accessor :s3

  def initialize(options={})
    adapter = Adapters::AWS.get_default_adapter
    s3_client = AWSSdkWrappers::S3::Client.new(adapter, ENV["REDSHIFT_REGION_ID"]).client
    @s3 = Aws::S3::Resource.new({name: Settings.right_size_bucket_name + "-" + ENV["REDSHIFT_REGION_ID"], client: s3_client})
    bucket_present = @s3.bucket(Settings.right_size_bucket_name + "-" + ENV["REDSHIFT_REGION_ID"]).exists?
    s3_client.create_bucket({bucket: Settings.right_size_bucket_name + "-" + ENV["REDSHIFT_REGION_ID"]}) unless bucket_present
  rescue Aws::S3::Errors => e
    CSLogger.error e.message
  rescue StandardError => e
    CSLogger.error e.message
  end

  def upload_price_list_to_s3
    is_already_uploded = s3.bucket(Settings.right_size_bucket_name + "-" + ENV["REDSHIFT_REGION_ID"]).object("price_listing/price_listing").exists?
    unless is_already_uploded
      CSLogger.info "uploading price_list_csv to s3 bucket...wait for while..."
      file_name = "Rightsizing/ec2pricelist.csv"
      system(`gzip -f #{file_name}`) if File.exist?(file_name)
      key = "#{CommonConstants::TABLE_PRICE_LISTING}/price_listing"
      obj = s3.bucket(Settings.right_size_bucket_name + "-" + ENV["REDSHIFT_REGION_ID"]).object(key)
      obj.upload_file("Rightsizing/ec2pricelist.csv.gz")
      CSLogger.info "uploading completed price_list_csv to s3 bucket..."
    end
  rescue Exception => e
    raise e
  end

  def upload_right_sizing_to_s3(account)
    file_name = "Rightsizing/#{account}/#{account}.csv.gz"
    if File.exist?(file_name)
      CSLogger.info "uploading cloudwatch csv file for #{account} to s3 bucket...wait for while..."
      key = "#{CommonConstants::TABLE_RIGHT_SIZING}/#{account}"
      obj = s3.bucket(Settings.right_size_bucket_name + "-" + ENV["REDSHIFT_REGION_ID"]).object(key)
      obj.upload_file(file_name)
      CSLogger.info "uploading completed csv file for #{account} to s3 bucket..."
    end
  rescue Exception => e
    CSLogger.error "exception while uploading cloudwatch metric data csv's to s3-->#{e.message}"
  end

end
