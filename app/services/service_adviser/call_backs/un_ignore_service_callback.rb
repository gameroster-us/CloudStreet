# frozen_string_literal: false

module ServiceAdviser
  module CallBacks
    # callback for auto un_ignore service worker
    class UnIgnoreServiceCallback
      def on_success(_status, _options); end

      def on_complete(_status, options)
        CSLogger.info "Successfully un-ignore service : #{options['service_name']}"
      end
    end
  end
end
