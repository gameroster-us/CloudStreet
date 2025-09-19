class MachineImageArchiver < CloudStreetService

  # mandatory type: values: adapter_id: 
  # optional region_id:
  # values "all" or ["ids"]
  def self.archive(options)
    options = JSON.parse(options)
    options.symbolize_keys!
    starttime = Time.now
    user = User.find(options[:user_id])
    if options[:adapter_id].eql?("all")
      account = Account.find(options[:account_id])
      unless options[:account_id].blank?
        options[:adapter_id] = account.adapters.normal_adapters.available.aws_adapter.ids
        adapters = Adapter.where(id: options[:adapter_id])
      end
    else
      adapters = Adapter.where(id: options[:adapter_id])
    end
    return if adapters.blank?
    adapters.each do |adapter|
      region_map = Region.where(adapter_id: Adapters::AWS.directoried.first.id).pluck(:id, :code).inject({}) do |region_map, res|
        region_map.merge!(res.first=> res.last)
      end
    if options[:image_ids].blank?
      amis_to_archive = []
      amis = MachineImage.unused_amis(options)
      amis.each do |service_advisor_formated_amis|
        service_advisor_formated_amis[1][0].list.each do |ami|
          amis_to_archive << {image_id: ami.image_id, region_id: ami.region_id, name: ami.name }
        end
      end
      unless options[:values].eql?("all")
        amis_to_archive = amis_to_archive.select { |res|
          options[:values].include?(res[:image_id])
        }
      end
      CSLogger.info "start removing amis #{amis_to_archive} for user #{user.username} by adapter #{adapter.name}"
    else
      amis_to_archive = []
      amis = MachineImage.where(id: options[:image_ids])
      amis.each do|ami|
        amis_to_archive << {image_id: ami.image_id, region_id: ami.region_id, name: ami.name }
      end
    end
    begin
      archived_amis = []
      amis_to_archive.group_by{|ami| ami[:region_id] }.each do|key, value|
        region_code = region_map[key]
        connection = adapter.connection(region_code)
        region = Region.find_by_code(region_code)
        value.each do|ami|
          begin
            remote_ami = connection.images.get(ami[:image_id])
            remote_ami.deregister(true) unless remote_ami.blank?
            Snapshots::AWS.where(image_reference: "#{region_code}-#{ami[:image_id]}").update_all(archived: true)
            archived_amis << ami[:image_id]
            ServiceAdvisorLog.log_ami_remove_event(adapter.account, user, ami[:name],'remove',"success")
          rescue Fog::Compute::AWS::Error => e
            CSLogger.error(e.message)
            ServiceAdvisorLog.log_ami_remove_event(adapter.account, user, ami[:name],'remove',"error",e.message)
          end
        end
        OrganisationImage.archive_templates_and_environments({
          adapter: adapter,
          region: region,
          archived_ami_ids: archived_amis
        })
      end

      begin
        ProviderWrappers::CentralApi::MachineImages.archive_images(archived_amis)
      rescue CentralApiNotReachable => e
        CSLogger.error(e.class)
        CSLogger.error(e.message)
        CSLogger.error(e.backtrace)
        Honeybadger.notify(e) if ENV["HONEYBADGER_API_KEY"]
      end
      CSLogger.info "Successfully removed amis"
    rescue Exception => e
      CSLogger.error "#{e.message} -------#{e.backtrace}"
    end

    end
  end
end
