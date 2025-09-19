require "./lib/node_manager.rb"
class Sync::FetchRemoteServicesWorker
  include Sidekiq::Worker
  sidekiq_options queue: :sync, backtrace: true

  def perform(options)
    CSLogger.info "Fetching Remote Services of | adapter_id - #{options['adapter_id']} | klass - #{options["klass"]}"
    adapter = Adapter.find(options["adapter_id"])
    region = Region.find_by(code: options["region_code"])
    account = Account.find_by(id: options["account_id"])
    synchronization = Synchronization.find(options["synchronization_id"])
    folder_name = get_folder_name(options['queue_name'])
    parent_directory = "public/#{folder_name}/#{adapter.aws_account_id}-#{account.id}"
    region_directory = "#{parent_directory}/#{region.code}"
    FileUtils.mkdir_p(parent_directory)
    FileUtils.mkdir_p(region_directory)
    begin
      remote_services = options["klass"].constantize.get_remote_service_list(adapter, region.code)
      CSLogger.info "Remote Services --- #{remote_services}" # CSLogger.info is added bcuz exception not get encountered above that why printed here to get exception if occurs.
    rescue Excon::Error::Socket => e
      synchronization.update_service_status(options["klass"].split('::')[-2], false, adapter.id)
      CSLogger.error "Error while fetching data from aws #{options["klass"].split('::')[-2]}"
      return
    rescue StandardError => e
      CSLogger.error "Error occured while fetching services #{options["klass"]}"
      return
    end
    service_type = options["klass"].eql?("AWSRecords::Network::ElasticIP::AWS") ? "AWSRecords::Network::ElasticIP::AWS" : options["klass"]
    parsed_services = CloudTrail::Processor.parse_form_hash_to_object(service_type, (remote_services || []).to_json)
    service_array = options["klass"].split("::")
    if(service_array[1].eql?("Snapshots") && service_array[2].eql?("Volume"))
      service_file = "VolumeSnapshot"
    elsif(service_array[1].eql?("Snapshots") && service_array[2].eql?("Rds"))
      service_file = "RdsSnapshot"
    elsif(service_array[3].eql? "Volume")
      service_file = "Volume"
    elsif service_type.eql?("AWSRecords::Network::ApplicationLoadBalancer::AWS")
      service_file = "ApplicationLoadBalancer"
    elsif service_type.eql?("AWSRecords::Network::NetworkLoadBalancer::AWS")
       service_file = "NetworkLoadBalancer"
    else
      service_file = service_array[2]
    end
    # Removing file if exist before with the same name
    FileUtils.rm("#{region_directory}/#{service_file.underscore}.yml") rescue nil
    File.open("#{region_directory}/#{service_file.underscore}.yml", "w") {|f| f.write parsed_services.to_yaml }
    synchronization.update_service_status(options["klass"].split('::')[-2], true, adapter.id)
    batch_status = Sidekiq::Batch::Status.new(batch.bid)
    adapter_data = {
      id: options["adapter_id"],
      name: options["adapter_name"],
      sync_state: Synchronization::RUNNING,
      total_count: batch_status.total,
      pending: batch_status.pending,
      failure_info: batch_status.failure_info,
      completed_count: batch_status.total - batch_status.pending,
      data: batch_status.data,
      phase: 2,
      start_percentage: 0,
      end_percentage: 30
    }
    ::NodeManager.send_sync_progress(options["account_id"], [adapter_data])
  end

  def get_folder_name(queue_name)
    if queue_name.eql?('background_aws_sync')
      'background-aws-sync'
    else # Might be if no queue name is present still it will take aws-sync
      'aws-sync'
    end
  end
end
