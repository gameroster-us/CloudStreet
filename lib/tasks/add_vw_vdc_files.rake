# frozen_string_literal: true
# rake add_vw_vdc_files:process[adapter_id]
# rake add_vw_vdc_files:process[20900c25-a7c4-44e2-aea0-6497b640b3a8]
namespace :add_vw_vdc_files do
  desc 'task to generate vw_vdc_files entry'
  task :process, [:adapter_id] => [:environment] do |_task, args|
    begin
      CloudStreet.log '======START connecting with S3 bucket========'
      adapter = Adapter.find_by(id: args.adapter_id)
      if adapter.blank?
        CloudStreet.log "---------- Adapter not present for id #{args.adapter_id} ----------"
        return
      end

      org_identifier = adapter.account.organisation_identifier
      bucket_name = ENV['S3_BUCKET_NAME']
      base_path = "uploads/vw_vdc_file/client_files/#{org_identifier}/#{adapter.id}"
      error_files = []
      vcenter_missing_files = []
      temp_dir = Dir.tmpdir
      CloudStreet.log "---------- temp_dir #{temp_dir} ----------"

      # Start listing and processing from the base path
      zip_files = list_zip_files(base_path, bucket_name)
      zip_files.each do |file_key|
        begin
          file_name = File.basename(file_key)
          if VwVdcFile.where(adapter_id: adapter.id, zip: file_name).any?
            CloudStreet.log"====== Record already present for this file #{file_name} ========"
            next
          end
          zip_data = read_file_data(file_key, bucket_name)
          create_vw_vdc_file(temp_dir, file_key, zip_data, adapter, vcenter_missing_files)
        rescue StandardError => e
          error_files << file_key
          CloudStreet.log("#{file_key} \n #{e.class} \n #{e.message} \n #{e.backtrace}")
        end
      end

      if error_files.present? || vcenter_missing_files.present?
        CloudStreet.log "====== Error Files detail :: #{error_files} and vcenter missing files :: #{vcenter_missing_files} ========"
        Honeybadger.notify(error_class: 'VwVdcFileGenerate::Rake', error_message: 'Error while processing zip files for VDC Data', parameters: { files_detail: error_files, vcenter_missing_files: vcenter_missing_files }) if ENV['HONEYBADGER_API_KEY']
      end
      CloudStreet.log '====== Rake execution done ========'
    rescue Exception => e
      CloudStreet.log("#{e.class} \n #{e.message} \n #{e.backtrace}")
      Honeybadger.notify(e, error_class: 'VwVdcFileGenerate::Rake', error_message: e.message, parameters: { adapter_id: args.adapter_id }) if ENV['HONEYBADGER_API_KEY']
    end
  end

  def list_zip_files(base_path, bucket_name)
    bucket = s3_client.bucket(bucket_name)
    bucket.objects(prefix: base_path).select do |obj|
      obj.key.end_with?('.zip')
    end.map(&:key)
  end

  def read_file_data(file_key, bucket_name)
    object = s3_client.bucket(bucket_name).object(file_key)
    object.get.body.read
  end

  def s3_client
    return @s3_client if @s3_client.present?

    aws_adapter = Adapters::AWS.get_default_adapter
    aws_client = AWSSdkWrappers::S3::Client.new(aws_adapter, ENV['S3_BUCKET_REGION']).client
    @s3_client = Aws::S3::Resource.new(client: aws_client)
  end

  def create_vw_vdc_file(temp_dir, file_key, zip_data, adapter, vcenter_missing_files)
    file_name = File.basename(file_key)
    file_path = File.join(temp_dir, file_name)

    File.open(file_path, 'wb') do |file|
      file.write(zip_data)
    end
    created_at = extract_timestamp_from_filename(file_name)
    vcenter_id = fetch_vcenter(adapter, file_name)
    if vcenter_id.blank?
      CloudStreet.log "====== Vcenter not found for this file #{file_name} ========"
      vcenter_missing_files << file_name
      return
    end

    record = adapter.vw_vdc_files.new(
      zip: File.open(file_path),
      created_at: created_at,
      updated_at: created_at,
      vw_vcenter_id: vcenter_id,
      additional_details: { is_manual_entry: true }
    )

    if record.save
      CloudStreet.log "====== Record Successfully created #{record.id}---#{file_name} ========"
    else
      CloudStreet.log "====== Failed to save file: #{file_name}, error:  #{record.errors.full_messages.join(', ')} ========"
    end
  ensure
    File.delete(file_path) if File.exist?(file_path)
  end

  def extract_timestamp_from_filename(file_name)
    timestamp = file_name.split('_').last.to_i
    Time.at(timestamp).utc
  end

  def fetch_vcenter(adapter, file_name)
    vcenter_global_id = file_name.split('_').first
    VwVdcFile.where(adapter_id: adapter.id).where('zip like ?', "%#{vcenter_global_id}%").last&.vw_vcenter_id
  end
end
