class ClearCloudTrailDataWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api, :retry => false

  def perform
    begin
      past_date = DateTime.now.beginning_of_day - 3.days
      # clear_data = CloudTrailEvent.where(event_time: { "$not" => { '$gte' => past_date  } } )
      # clear_data.delete_all

      clear_data = CloudTrailEvent.collection.find({"event_time"=> { "$not" => { '$gte' => past_date }}})
      count = clear_data.count()
      limit = 50000
      while (count > 0)
        batch = clear_data.limit(limit)
        CSLogger.info "=============Deleting=================#{count}"
        res = CloudTrailEvent.collection.delete_many({_id: {"$in": batch.pluck(:_id) }})
        count = count - limit
      end
      CSLogger.info "Cloud Trail Event data cleaned successfully!!"
    rescue Exception => e
      CSLogger.error "#{e.message} ---#{e.backtrace}"
    end
  end
end
