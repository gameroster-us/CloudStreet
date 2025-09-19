class CloudTrailEvent
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  index({ event_id: 1 })
  index({ event_id: 1, adapter_id: 1 }, { unique: true })
  index({ adapter_id: 1 })
  index({ adapter_id: 1, status: 1, event_name: 1 })
  index({ adapter_id: 1, error_code: 1, event_name: 1 })
  index({ event_name: 1 })
  index({ event_time: 1 })
  index({ status: 1 })

  STATUS = { success: 'success', pending: 'pending',
    failure: 'failure', skipped: 'skipped', skipped_as_not_found: "skipped_as_not_found",
    vpc_exists: "vpc_exists", invalid_format: "invalid event format" }

  def self.filtered_data(adapter, event_time = nil)
    filter = [
      { "adapter_id": { "$eq": "#{adapter.id}" } },
      { "status": {"$eq": 'pending'} }
    ]
   filter << { "event_time": { "$lt": event_time } } if event_time
    result = CloudTrailEvent.collection.aggregate([
      {
       "$match": {
        "$and": filter
      }
    }
   ]).as_json
  end

  def self.update_status(adapter)
    last_sync_time = adapter.get_last_sync_start_time
    result = filtered_data(adapter, last_sync_time)
    return if result.blank?
    event_ids = result.pluck('event_id')
    where(adapter_id: adapter.id,:event_id.in => event_ids).update_all(status: STATUS[:success])
  end

  def self.grouped_events(adapter)
    filter = [
      { "adapter_id": { "$eq": "#{adapter.id}" } },
      { "status": { "$eq": 'pending' } }
    ]
    #Processing time considering only for suncorp account adapters
    filter << { "event_time": { "$gt": (Time.now.utc - 6.hours) } } if adapter.account_id == 'e0f081c2-c176-4f2c-868a-188fd4b523ae'
    result = CloudTrailEvent.collection.aggregate([
      {
        "$match": {
          "$and": filter
        }
      },
      {
        "$group": {
          "_id": {
            "service_type": "$service_type",
            "event_name": "$event_name",
            "region_code": "$region_code"
          },
          "event_data": {
            "$addToSet": {
              "resources": "$resources",
              "cloud_trail_event": "$cloud_trail_event"
            }
          }
        }
      },
      {
        "$group": {
          "_id": "$_id.service_type",
          "group_events": {
            "$addToSet": {
              "event_name": "$_id.event_name",
              "event_data": "$event_data",
              "region_code": "$_id.region_code"
            }
          }
        }
      },
      {
        "$project": {
          "_id": false,
          "service_type": "$_id",
          "group_events": "$group_events"
        }
      }
    ],
      {
          'allowDiskUse': true
      }
    ).as_json
  end

  def self.select_create_vpc_event_to_execute(adapters)
    event_adapter_ids = where(:adapter_id.in => adapters.map(&:id), event_name: "CreateVpc", status: "pending").map(&:adapter_id)
    return if event_adapter_ids.blank? || adapters.blank?
    adapters = adapters.select { |a| event_adapter_ids.include?(a.id) }
    latest_adapter = adapters.sort_by { |adapter| adapter.created_at }.pop
    other_adapter_ids = adapters.map(&:id) - [latest_adapter.id]
    return if other_adapter_ids.blank?
    where(:adapter_id.in => other_adapter_ids, event_name: "CreateVpc", status: "pending").update_all(status: "success")
  end
end
