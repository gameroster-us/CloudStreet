# frozen_string_literal: true

# This will execute the reporting actions for slack.
module Integrations::Slack::SlackReporting
  # all class specific methods will be here
  module ClassMethods
    def send_ri_notifications_to_slack(params)
      ri_instance = ReservedInstances::Notification::SlackNotification.new(params)
      ri_instance.send("#{params[:method_name]}")
    end
  end

  # all instance specific method will be here
  module InstanceMethods
  end

  def self.included(receiver)
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
  end
end
