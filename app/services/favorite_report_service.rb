class FavoriteReportService < CloudStreetService
  class << self
    CS_GROUP = 'CSgroup'
    def notifier(params, &block)
      begin
        inactive_emails = User.by_organisation(params[:organisation_id]).in_active.pluck(:email)
        result_emails = (params[:mail_ids] - inactive_emails).compact.uniq
        result_emails.each do |m_id|
          CustomerioNotifier.favorite_report_email(params[:fav_report_name], params[:fav_id], m_id, params[:mail_frequency],params[:subdomain], params[:fav_scheduled_name], params[:account_id])
        end
        organisation = Organisation.find_by(subdomain: params[:subdomain])
        if organisation.present? && params[:role_ids].present?
          options = {:organisation_object => organisation, :user_role_ids => params[:role_ids], :favourite_report_name => params[:fav_report_name], :report_id => params[:fav_id], :mail_frequency => params[:mail_frequency], :subdomain => params[:subdomain], fav_scheduled_name: params[:fav_scheduled_name]}
          FavouriteReport::Notification::SlackNotification.new(options).send_favourite_cost_report
        end
        status Status, :success, {}, &block
      rescue Exception => e
        Honeybadger.notify(e, error_class: "FavouriteReportService", error_message: "#{e.message}", parameters: {params: params})
      end
    end
  end
end
