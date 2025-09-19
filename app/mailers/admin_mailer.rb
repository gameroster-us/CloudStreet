class AdminMailer < ActionMailer::Base
  default from: "michael@cloudstreet.com"
  after_action :set_delivery_options

  def weekly_summary(file_path, filename)
    attachments["#{filename}"] = File.read("#{file_path}", encoding: 'BINARY')
    mail(to: 'michael@cloudstreet.com', subject: "Weekly Summary: #{filename}", bcc: 'ml-sales@cloudstreet.com, CSas@cloudstreet.com')
  end

  def es_summary(file_path, filename)
    attachments["#{filename}"] = File.read("#{file_path}", encoding: 'BINARY')
    mail(from: "Support@cloudstreet.com", to: 'srani@cloudstreet.io, vyelapale@cloudstreet.io, csingh@cloudstreet.io, agore@cloudstreet.io', subject: "Event Scheduler Tasks Summary: #{filename}")
  end

  def send_user_info(user)
    #Commented as it fails to signup the new user registration
    @user = user
    mail(to: 'michael@cloudstreet.com', subject: "New User: #{@user.username}")
  end

  private

  def set_delivery_options
    delivery_options = { user_name: ENV["SES_USERNAME"],
                         password: ENV["SES_PASSWORD"],
                         address: ENV["SES_ADDRESS"], # 'email-smtp.us-west-2.amazonaws.com',
                         port: 587,
                         authentication: :login }
    mail.delivery_method.settings.merge!(delivery_options)
  end
end
