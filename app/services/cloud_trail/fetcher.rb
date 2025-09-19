class CloudTrail::Fetcher < CloudStreetService

  EVENTS = YAML.load_file(Rails.root.join("config/cloud_trail_events.yml"))
  EVENT_NAMES = EVENTS.each_with_object([]) { |(key, value), arr| arr.concat(value["events"]) if value["events"].present? && value["resource_type"].present? }
  class << self

    def fetch_events(adapter, region_codes, adapters, batch_id)
      region_codes.reject! { |region_code| adapter.not_supported_regions.include?(region_code) } # Skipping the region which are not supported
      parent_batch = Sidekiq::Batch.new(batch_id)
      parent_batch.jobs do
        event_fetcher_batch = Sidekiq::Batch.new
        event_fetcher_batch.description = "ClousTrail Event Fetcher Batch"
        callback_params = {
            aws_account_id: adapter.aws_account_id,
            sync_adapter_id: adapter.id,
            other_adapter_ids: adapters.map(&:id),
            batch_id: batch_id
          }
        CTLog.info "** ClousTrail Event Fetcher Batch  #{adapter.id} | #{adapter.aws_account_id} **"
        CTLog.info "4.****************CT Callback Params***************** #{callback_params.inspect}"
        event_fetcher_batch.on(:complete, EventFetcherCallback, callback_params)
        event_fetcher_batch.on(:success, EventFetcherCallback, callback_params)
        event_fetcher_batch.jobs do
          region_codes.each do |region_code|
            CloudTrail::EventFetcherWorker.perform_async(adapter.id, region_code, adapters.map(&:id))
          end
        end
      end
    end

    def replicate_event_data(sync_adapter, other_adapters)
      CTLog.info "8.****************Replicate Event Data from #{sync_adapter.id} adapter to***************** #{other_adapters.count} ************* #{other_adapters.pluck(:id)}"
      region_codes = Region.aws.where.not(code: sync_adapter.not_supported_regions).pluck(:code) # Skipping the region which are not supported
      region_codes.each do |region_code|
        other_adapters.each do |other_adapter|
          CTLog.info "===Started replicate_event_data for region : #{region_code}, adapter: #{other_adapter.name}"
          begin
            other_adapter_trail_event_log = CloudTrailEventLog.last_event(other_adapter.id, region_code)
            next if other_adapter_trail_event_log.blank?
            start_time = other_adapter_trail_event_log.event_time
            end_time   = CloudTrailEventLog.where(adapter_id: sync_adapter.id, region_code: region_code).first.event_time
            all_events = CloudTrailEvent.where(adapter_id: sync_adapter.id, region_code: region_code, :event_time.gte => start_time, :event_time.lte => end_time)
            all_events.each_slice(5000).with_index do |events, index|
              CTLog.info "=== Processing exisiting Event batch : #{index + 1} -- region: #{region_code} -- adapter: #{other_adapter.name}"
              events = events.as_json.each do |event|
                event.delete("_id")
                event["adapter_id"] = other_adapter.id
                event["account_id"] = other_adapter.account_id
              end
              existing_ids = CloudTrailEvent.where(adapter_id: other_adapter.id, :event_id.in => events.map { |e| e["event_id"] }).pluck(:event_id)
              events.reject! { |e| existing_ids.include?(e["event_id"]) }
              CloudTrailEvent.collection.insert_many(events, ordered: false) unless events.blank?
              other_adapter_trail_event_log.update(event_time: end_time)
              unless events.blank?
                trails_data = []
                events.each do |trail|
                  next if CommonConstants::TAG_EVENT_TYPES.include?(trail["event_name"])
                  next unless trail["error_code"].nil?

                  CloudTrail::Storer.set_provider_id_for_event(trail)
                  trails_data << trail
                end
                CloudTrailLog.collection.insert_many(trails_data, ordered: false) if trails_data.any?
              end
            end
          rescue Mongo::Error => e
            Honeybadger.notify(e) if ENV["HONEYBADGER_API_KEY"]
            Bugsnag.notify(e) if ENV["BUGSNAG_API_KEY"]
            if e.class.eql?(Mongo::Error::BulkWriteError)
              errors = e.result["writeErrors"] if e.result && e.result.key?("writeErrors")
              if errors.present?
                errors.each do |err|
                  Honeybadger.notify(err) if ENV["HONEYBADGER_API_KEY"]
                  Bugsnag.notify(err) if ENV["BUGSNAG_API_KEY"]
                  CTLog.error "--- Duplicate key error-- #{err['errmsg']}"
                end
              end
            else
              CTLog.error e.message
              CTLog.error e.backtrace
            end
          rescue StandardError => e
            Honeybadger.notify(e) if ENV["HONEYBADGER_API_KEY"]
            Bugsnag.notify(e) if ENV["BUGSNAG_API_KEY"]
            CTLog.error e.message
            CTLog.error e.backtrace
          ensure
            other_adapter.aws_cloud_trail.update(running: false)
            CTLog.info "9.****************Inside Replicate Event Data - Adapters after CT Running=false***************** #{AWSCloudTrail.where(adapter_id: other_adapter.id).pluck(:adapter_id, :running)}"
          end
        end
      end
     end

    def update_error_and_skip_event_status(merged_adapter_ids)
      CloudTrailEvent.where(:adapter_id.in => merged_adapter_ids, status: CloudTrailEvent::STATUS[:pending]).any_of({:error_code.nin => ["", nil]}, {:event_name.in => CloudTrail::Processor.events('skip')}).update_all(status: CloudTrailEvent::STATUS[:skipped])
    end

 end

  class EventFetcherCallback

    def on_complete(status, options)
      CTLog.info "*** ClousTrail Event Fetcher complete #{options['sync_adapter_id']} | #{options['aws_account_id']} ***"
      CTLog.info "event fetch complete===options===#{options}"
      sync_adapter = Adapter.find(options["sync_adapter_id"])
      sync_adapter.aws_cloud_trail.update(running: false)
      CTLog.info "7.****************EventFetcherCallback - Adapters after CT Running=false***************** #{AWSCloudTrail.where(adapter_id: sync_adapter.id).pluck(:adapter_id, :running)} *************"
      other_adapters = Adapter.where(id: options["other_adapter_ids"])
      merged_adapter_ids = [*options["sync_adapter_id"]] + options["other_adapter_ids"]
      CloudTrail::Fetcher.update_error_and_skip_event_status(merged_adapter_ids)
      CloudTrail::Fetcher.replicate_event_data(sync_adapter, other_adapters) unless other_adapters.blank?
      CloudTrail::Processor.start_processing(options["aws_account_id"], options['batch_id'])
      if status.failures != 0
        CTLog.error "EventFetcherCallback, batch has failures"
      else
        CTLog.info "EventFetcher completed"
      end
     end

    def on_success(status, options)
      CTLog.info "*** EventFetcher success ***"
     end

  end

end
