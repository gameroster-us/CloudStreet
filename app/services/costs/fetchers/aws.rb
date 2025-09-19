class Costs::Fetchers::AWS < Costs::Fetcher
  attr_accessor :adapter

  def initialize(adapter, options)
    super
    @bucket_id = adapter.bucket_id
  end

  def fetch
    # from_date.to_date.step(to_time.to_date).map do |date|
    begin
      file_name = log_file_name
      CSLogger.info "---Fetching file #{file_name}"
      remote_file = billing_directory.files.get(file_name)
      return false if remote_file.nil?
      local_file = save_in_local_machine(remote_file)
      # local_file = File.open file_name
      local_file.close
    rescue => e
      CSLogger.error "Error while fetching file for adapter #{adapter.id}----#{e.message}"
      CSLogger.error "#{e.backtrace}"
      return false
    end
    local_file
  end

  private

  def save_in_local_machine(remote_file)
    file_content_str = remote_file.body
    file_encoding    = file_content_str.encoding.name

    local_file = File.open(remote_file.key, "w+:#{file_encoding}")
    local_file.write file_content_str
    local_file
  end

  def log_file_name
    "#{adapter.aws_account_id}-aws-billing-detailed-line-items-with-resources-and-tags-#{date.strftime('%Y-%m')}.csv.zip"
  end

  def billing_directory
    aws_storage_agent.directories.get(@bucket_id) rescue nil
  end

  def aws_storage_agent
    @aws_storage_agent ||= adapter.bucket_storage_connection
  end
end
