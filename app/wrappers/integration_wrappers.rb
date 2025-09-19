class IntegrationWrappers
	
  class << self
		def http_process(base_url, api, verb, body={}, headers={})
      http_obj = IntegrationWrappers::HTTPService.new(base_url,api,verb,body, headers)
      http_obj.init_http
      http_obj.init_request
			return http_obj.send_request
		end

    def retry_on_timeout(&block)
      retries ||= 0
      yield
    rescue Excon::Error::Socket, Excon::Error::Timeout => e
      print "Excon Exeption:: => #{e.message}.Retrying ." if retries.eql?(0)
      if (retries += 1) < 3
        sleep 5
        print "."
        retry
      else
        CSLogger.error "Retry failed."
        CSLogger.error "Error : #{e.message}"
        CSLogger.error "BackTrace   : #{e.backtrace}"
      end
    end
  end

end
