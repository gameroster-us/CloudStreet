require "./lib/node_manager.rb"
class AlertService < CloudStreetService
  def self.set_alert(params)
    CSLogger.info "params to set_alert=#{params.inspect}"
    ESLog.info "params to set_alert=#{params.inspect}" if params[:code].eql?(:task_data_prepared)
    Thread.new do 
      begin
        http, uri = ::NodeManager.new.http_connect("notifications")
        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form_data(params)
        response = http.request(request)
      rescue Exception => e
        CSLogger.error "node connection failed=#{e.message}"
      end
    end
  end
end
