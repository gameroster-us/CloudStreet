require "#{Rails.configuration.root}/lib/fog/aws/rds/start_db_instance_real.rb"
require "#{Rails.configuration.root}/lib/fog/aws/rds/stop_db_instance_real.rb"
require "#{Rails.configuration.root}/lib/fog/parsers/aws/rds/describe_db_instances.rb"
require "#{Rails.configuration.root}/lib/fog/parsers/aws/rds/db_parser.rb"
require "#{Rails.configuration.root}/lib/fog/aws/compute/server.rb"

class ProviderWrappers::AWS::Databases::Rds < ProviderWrappers::AWS
  attr_reader :rds_id

  def fetch_remote_volume(database_id)
    ProviderWrappers::AWS.retry_on_timeout{
      agent.databases.get(database_id) if database_id
    }
  end

  def create_backup(database_id, options)
    ProviderWrappers::AWS.retry_on_timeout{
      @agent.create_db_snapshot(database_id, options[:target_backup_name]).data[:body]["CreateDBSnapshotResult"]["DBSnapshot"]["DBSnapshotIdentifier"]
    }
    options[:target_backup_name]
  rescue Fog::Compute::AWS::Error => e
    CSLogger.error "Error occured while creating db snapshot #{e.message}"
  end

  def update(update_params)
    CSLogger.info "-------------------------------update_params-lib----#{update_params}"
    name  =  service.name
    service.modifying
    apply_immediately = "true"
    agent.modify_db_instance(name, apply_immediately, service.updated_provider_attrs(update_params['service_attribute'])) if service.provider_id
    sleep(10)

    if name == update_params['service_attribute']['name']
      @rds_id = name
    else
      @rds_id = update_params['service_attribute']['name']
    end
    wait_for(timeout_time: 45.minutes, polling_time: 45.seconds, &method(:is_remote_rds_not_in_available_state?))
    agent.servers.get(@rds_id)
  end

  def get_remote_rds(name=service.provider_id)
    if name
      ProviderWrappers::AWS.retry_on_timeout{
        agent.servers.get(name)
      }
    else
      return false
    end
  end

  def list_tags(id)
    agent.list_tags_for_resource(id).data[:body]["ListTagsForResourceResult"]["TagList"]
  end

  def create_db_cluster(cluster_params)
    agent.clusters.create(cluster_params) if !get_cluster(cluster_params).present?
  end

  def get_cluster(cluster_params)
    agent.clusters.get(cluster_params[:db_cluster_identifier]) if cluster_params[:db_cluster_identifier]
  end

  class << self
    def all(agent, filters = {})
      retry_on_timeout {
        servers = agent.servers.all
        servers = servers.select{|server| filters[:engines].include?(server.engine)} if filters[:engines].present?
        return servers
      }
    end
    def get(agent, rds_id)
      agent.servers.get(rds_id)
    end

    def start_db_instance(agent, database_id)
      agent.start_db_instance(database_id)
    end

    def stop_db_instance(agent, database_id)
      agent.stop_db_instance(database_id)
    end

  end

  private

  def is_remote_rds_available?
    remote_rds = get_remote_rds @rds_id
    return false if remote_rds.blank?
    remote_rds.state == 'available'
  end

  def is_remote_rds_not_in_available_state?
    !is_remote_rds_available?
  end
end
