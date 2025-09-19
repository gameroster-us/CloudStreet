class CloudTrailEventLog
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  index({ region_code: 1, adapter_id: 1 }, { unique: true })

  def self.last_event(adapter_id, region_code)
    event = find_or_create_by(region_code: region_code, adapter_id: adapter_id)
    last_seven_datetime = (DateTime.now - 7.days).utc.beginning_of_day
    event.update(event_time: last_seven_datetime) unless event.try(:event_time)
    event
  end
end
