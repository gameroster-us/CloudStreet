class AlertNotifier < CloudStreetService
  class << self
    def create_archived_amis_notifications(number_of_amis_archived)
      User.all.each do |user|
        # alert = Alert.initialize_info_alert(:amis_archived_alert, {
        #   archive_count: number_of_amis_archived
        # })
        # user.alerts << alert
        user.create_info_alert(:amis_archived_alert, { archive_count: number_of_amis_archived })
      end
    end
  end
end