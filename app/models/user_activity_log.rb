class UserActivityLog
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  attr_accessor :display_time_zone

  field :account_id
  field :browser
  field :ip_address
  field :lock_version, type: Integer #Provides Optimistic Locking
  
  #module
  field :module_name #(eg, Adapter, Region, EventScheduler, Environment, Template, ServiceAdviser, Synchronizer, ServiceAdviser etc)
  field :action_name #(eg Create, Update, Delete, Terminate, Start, Stop, Move, reload etc)
  field :action_status #(eg success/failure)
  field :action_message #display message
  
  #resource that modify
  field :resource_name #name of object
  field :resource_id #uuid of object
  field :resource_type # (Adapter, Region, Event, Environment, Template,sync,volume,server,rds etc)
  field :resource_kclass_name # ("Adapters::AWS", "Services::Compute::Server", "Services::Database::Rds", "Environment","Region", "Services::Vpc", "Template")
  field :resource_owner #(CloudStreet/AWS/Azure)
  field :resource_previous_state #state of resource before modify
  field :resource_current_state #state of resource after modify
  field :resource_error_message #if any error occur in object
  field :response_key #key that define in en.yml 
  field :resource_adapter_name #name of adapter
  field :resource_region_name #name of region
  field :resource_destination_adapter_name #name of adapter(only different in the time of backup)
  field :resource_destination_region_name#name of region(only different in the time of backup)
  #responsible for action (user/sync/CT/Task)
  field :action_owner_id#if user/sync/task 
  field :action_owner_name# if user/sync name
  field :action_owner_kclass_name# user/sync class name

  field :activity_date   
  field :user_activity_id #user activity id (parent id)
  field :user_activity_log_id #self reference for env and sync
  field :resource_dry_run #event run as a dry run(testing mode)
 
  #add_index
  #This is a global module so do not add foreign key. 
  index({ account_id: 1})
  index({ resource_id: 1})
  index({ action_status: 1})
  index({ activity_date: 1})
  index({ module_name: 1})
  index({ account_id: 1, resource_id: 1})
  index({ resource_id: 1, resource_kclass_name: 1})


  #default_scope
  scope :by_account_id, -> (account_id) { where(account_id: account_id) }
  scope :by_action_owner_id, -> (owner_id)  { where(action_owner_id: owner_id) }
  scope :by_resource_owner, -> (owner) { where(resource_owner: owner) }
  scope :by_action_status, -> (status) { where(action_status: status) }
  scope :by_module_name, -> (module_name) { where(module_name: module_name) }
  scope :by_resource_id, -> (id) { where(resource_id: id) }
  scope :from_date, -> (date) { where(:created_at.gte => date) }
  scope :till_date, -> (date) { where(:created_at.lte => date.to_date.end_of_day) }
  scope :by_user_activity_id, -> (user_activity_id) { where(user_activity_id: user_activity_id) }

  #this contain resource type except service table

  RESOURCE_TYPE = { 'Environment' => 'Environment',
                    'Adapters::AWS' => 'Adapters',
                    'Services::Compute::Server::Volume::AWS' => 'Volume',
                    'Services::Network::LoadBalancer::AWS' => 'LoadBalancer',
                    'Services::Database::Rds::AWS' => 'Rds',
                    'Services::Compute::Server::AWS' => 'Server',
                    'Services::Network::AutoScaling::AWS' => 'AutoScaling',
                    'Synchronization' => 'Synchronization',
                    'Snapshots::AWS' => "Snapshot",
                    'Azure::Resource::Compute::VirtualMachine' => 'Virtual Machine',
                    'VwInventory' => 'Inventory'
                  }


  def set_response(activity_status)
    self.response_key = activity_status
  end

  def set_account_for_activity(account_id)
    self.account_id = account_id
  end

  class << self
    def init_activity(service,options,owner_data)
      set_activity_params = 
         {
            module_name: options[:module_name],
            action_name: options[:action_name],
            action_status: options[:action_status],
            action_message: options[:action_message],
            resource_owner: options[:resource_owner],

            action_owner_id: owner_data[:action_owner_details].try(:id),
            action_owner_name: options[:module_name] == "Event Scheduler" ? owner_data[:action_owner_details].title : owner_data[:action_owner_details].name,
            action_owner_kclass_name: owner_data[:action_owner_details].class.to_s,
            activity_date: Time.now,
            resource_error_message: options[:resource_error_message].present? ? options[:resource_error_message] : " " ,
            response_key: owner_data[:response_key].present? ? owner_data[:response_key] : " ",
            user_activity_id: owner_data[:user_activity_id].present? ? owner_data[:user_activity_id] : nil,
            resource_dry_run: owner_data[:action_owner_details].try(:is_dry_run),
            action_user: owner_data[:action_user].try(:name) || owner_data[:action_user].try(:username),
            account_id:  owner_data[:from].eql?('recommendation_service') ? owner_data[:account_id] : nil,
            adapter_group_name: owner_data[:from].eql?('recommendation_service') ? owner_data[:adapter_group_name] : nil,
            no_user_email: owner_data[:from].eql?('recommendation_service') ? owner_data[:no_user_email] : nil
          }
      if service.present?
        service = service.recommendation_service if owner_data[:from].eql?('recommendation_service')
        set_activity_params.merge!(
          account_id: get_account_id(service, owner_data),
          resource_name: service_name(service, options),
          resource_id: service.id,
          resource_type: RESOURCE_TYPE[service.class.to_s].present? ? RESOURCE_TYPE[service.class.to_s] : service.class.name,
          resource_kclass_name: service.class.to_s,
          resource_previous_state: owner_data[:resource_previous_state],
          resource_current_state: service.class.name.eql?('VwInventory') ? service.inventory_state : service.try(:state),
          resource_adapter_name: adapter_name(service),
          resource_region_name: region_name(service),
          resource_destination_adapter_name: owner_data[:resource_destination_adapter_name].nil? ? adapter_name(service) : owner_data[:resource_destination_adapter_name],
          resource_destination_region_name: region_name(service)
        )
      end
      update_user_activity(owner_data)
      create_activity_log(set_activity_params)
    end

    def adapter_name(service)
      if service.class.name.eql?("MachineImage")
        service.adapter_name
      elsif service.class.name.eql?('VwInventory')
        service.inventory_adapter.name
      else
        service.class.name == "Environment" ? service.try(:default_adapter).try(:name) : service.try(:adapter).try(:name)
      end
    end

    def region_name(service)
      return service.class.name == "Services::Network::LoadBalancer::AWS" ? find_region_name(service.region_id) : service.try(:region).try(:region_name)
    end

    def service_name(service,options)
      if (service.class.name == "Services::Compute::Server::AWS" && options[:action_name] == "backup")
        attch_volume_name = service.server_attached_volumes.map { |h| h["name"] }
        return service.try(:name) + ' with volume(s) ' + attch_volume_name.join(",")
      elsif service.class.name.eql?('VwInventory')
        service.tag
      else
        return service.try(:name)
      end
    end
    
    def find_region_name(region_id)
      return Region.find(region_id).try(:region_name) if region_id.present?
    end

    def create_activity_log(set_activity_params)
      activity = UserActivityLog.create(set_activity_params)
      activity
    end

    def update_user_activity(owner_data)
      user_acrivity = UserActivity.find(owner_data[:user_activity_id])
      progress_data = owner_data[:action_owner_details].progress
      user_acrivity.update(:progress => progress_data)
    end

    def get_account_id(service, owner_data)
      if ["Adapters::AWS", "Adapters::Azure"].include?(service.class.name)
        service.try(:account).try(:id)
      elsif ["MachineImage", "VwInventory"].include?(service.class.name)
        owner_data[:action_owner_details]&.account_id
      else
        service.class.name == "Environment" ? service.try(:default_adapter).try(:account).try(:id) : service.try(:adapter).try(:account).try(:id)
      end
    end

  end
end
