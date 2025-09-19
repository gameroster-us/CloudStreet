# frozen_string_literal: true

CarrierWave.configure do |config|
  config.fog_provider = 'fog/aws'
  config.fog_directory = ENV['S3_BUCKET_NAME']
  config.fog_public    = false

  config.fog_credentials = {
    provider: :aws, # required
    aws_access_key_id: Rails.application.secrets['aws_access_key_id'],
    aws_secret_access_key: Rails.application.secrets['aws_secret_access_key'],
    region: ENV['S3_BUCKET_REGION']
  }
end
