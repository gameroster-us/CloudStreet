class GeneralSettings::Updater < CloudStreetService

  def self.update_general_setting(current_account, params, &block)
    general_setting = GeneralSetting.find_by(account_id: current_account[:id])
    general_setting.email_domain = params["email_domain"] if params["email_domain"].present?
    general_setting.is_tag_case_insensitive = params["is_tag_case_insensitive"].to_s.downcase.eql?("true")
    general_setting.time_zone = params["time_zone"] if params["time_zone"].present?
    if general_setting.valid?
      general_setting.save
      status Status, :success, general_setting, &block
    else
      status Status, :validation_error, general_setting, &block
    end
  end

  def self.get_general_setting(current_account, &block)
    general_setting = GeneralSetting.find_by(account_id: current_account[:id])

    status Status, :success, general_setting, &block
  end

end
