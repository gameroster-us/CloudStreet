class MachineImageFetcher
  class << self
    def fetch_ami(adapter, region, filters)
      raw_machine_images = adapter.fetch_amis(region, filters)
      save_machine_images(adapter, region, raw_machine_images)
    end

    def fetch_amis(adapter, region, filters)
      begin
        CSLogger.info("#{Time.now} : Started fetching AMIs from region #{region.region_name}!")
        raw_machine_images = adapter.fetch_amis(region, filters)

        CSLogger.info("#{Time.now} : Finished fetching AMIs from region #{region.region_name} attempting to save!")
        save_machine_images(adapter, region, raw_machine_images)
        # Fix for Error Message: undefined method `collect' for true:TrueClass.
        raw_machine_images = raw_machine_images.eql?(true) ? [] : raw_machine_images
        return if raw_machine_images.blank?
        active_ami_ids = raw_machine_images.collect{|ami| ami["imageId"] }.compact.uniq
        OrganisationImage.where(image_id: active_ami_ids).update_all(is_public: false)
        CSLogger.info("#{Time.now} : Finished saving AMIs from region #{region.region_name}!")
        archived_ami_ids = adapter.images.region_id(region.id).where({active: true, is_public: false}).where.not(image_id: active_ami_ids).pluck(:image_id)
        OrganisationImage.archive_templates_and_environments({ adapter: adapter,
                                                               region: region,
                                                               archived_ami_ids: archived_ami_ids
        })
        filters = {active: true, provider: "aws", image_owner_id: adapter.aws_account_id, region: region.code } 
        public_amis = ProviderWrappers::CentralApi::MachineImages.find(filters) rescue []
        security_scanner = SecurityScanner.new("MachineImage", adapter, region, public_amis.pluck(:image_id) + archived_ami_ids, false)
        security_scanner.start_scanning
        CSLogger.info("#{Time.now} : Finished removing inactive AMIs from region #{region.region_name}!")
      rescue ::Adapters::InvalidAdapterError => e
        CSLogger.error e.message
      rescue ArgumentError => error
        CSLogger.error error.message
      rescue Exception => exception
        CSLogger.error("An Error occured for #{region.region_name}!")
        CSLogger.error("Error Message: #{exception.message}")
        CSLogger.error("Error Backtrace: #{exception.backtrace}")
        Honeybadger.notify(exception) if ENV["HONEYBADGER_API_KEY"]
      end
    end

    def save_machine_images(adapter, region, raw_machine_images=nil)
      groups = MachineImageGroup.where(region_id: region.id).all
      # Fix for Error Message: undefined method `each' for true:TrueClass.
      raw_machine_images = raw_machine_images.eql?(true) ? [] : raw_machine_images
      return if raw_machine_images.blank?
      generic_adapter_id = adapter.generic_adapter.id
      raw_machine_images.each do |raw_machine_image|
        cost = MachineImage.calculate_and_update_hourly_cost(raw_machine_image)
        raw_machine_image["cost_by_hour"] = cost
        raw_machine_image["region"] = region.code
        if raw_machine_image["isPublic"].eql?(true)
          begin
            ProviderWrappers::CentralApi::MachineImages.create(raw_machine_image)
          rescue CentralApiNotReachable => e
            CSLogger.error(e.class)
            CSLogger.error(e.message)
            CSLogger.error(e.backtrace)
            Honeybadger.notify(e) if ENV["HONEYBADGER_API_KEY"]
          end
        else
          begin
            ami = MachineImage.create_machine_image(adapter, region, raw_machine_image, generic_adapter_id)
            ami.assign_best_matching_group(groups) if ami.new_image? || ami.machine_image_group_id == nil
            # org_images = OrganisationImage.where(image_id: ami.image_id)
            # org_images.update_all(aws_account_id: ami.aws_account_id) if org_images.present?
            AdaptersMachineImage.find_or_create_by({adapter_id: adapter.id, machine_image_id: ami.id})
          rescue Exception => error
            CSLogger.error("Image Id : #{raw_machine_image['image_id']}")
            CSLogger.error("Error Message #{error.message}")
            CSLogger.error("Error Message #{error.backtrace}") unless error.message.include?("UniqueViolation")
          end
        end
        find_and_update_volume_snapshot_references(raw_machine_image, region, adapter)
      end

      #get not active ids from org image table  negating "image_ids"
      #ask central api which of these ids are inactive
      #Organisationimages where ids in inactive image ids update all to active false

    end

    def find_and_update_volume_snapshot_references(raw_machine_image, region, adapter)
      image_id = raw_machine_image["imageId"]
      image_reference = "#{region.code}-#{image_id}"
      if raw_machine_image["rootDeviceType"] == "ebs"
        provider_snapshot_ids = raw_machine_image["blockDeviceMapping"].map { |h| h["snapshotId"]}.compact.uniq
        provider_snapshot_ids_exist = Snapshot.where(provider_id: provider_snapshot_ids).pluck(:provider_id)
        Snapshot.where(provider_id: provider_snapshot_ids_exist).update_all(image_reference: image_reference)
        [provider_snapshot_ids - provider_snapshot_ids_exist].each do |snapshot_id|
          create_volume_snapshot(adapter, region, snapshot_id, image_reference)
        end
      end
    end

    def create_volume_snapshot(adapter, region, snapshot_id, image_reference)
      agent = ProviderWrappers::AWS::Computes::Snapshot.compute_agent(adapter, region.code)
      volume_snapshot = agent.snapshots.get(snapshot_id)
      unless volume_snapshot.blank?
        data = JSON.parse(volume_snapshot.to_json)
        obj = AWSRemoteServiceObject::Snapshot::Volume.parse_from_json(data)
        attrs = obj.get_attributes_for_service_table
        attrs.merge!({adapter_id: adapter.id, account_id: adapter.account_id,
                      region_id: region.id, image_reference: image_reference })
        snapshot = Snapshots::AWS.new(attrs)
        snapshot.save
      end
    end
  end
end
