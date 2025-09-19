class InstanceProfileService < CloudStreetService
  class << self
    def get_instance_profile_role
      if system('curl -I http://169.254.169.254/latest/meta-data/iam/info| grep "200 OK"')
        iam_info = JSON.parse(`curl http://169.254.169.254/latest/meta-data/iam/info`)
        if iam_info["Code"].eql?("Success")
          instance_profile_arn = iam_info["InstanceProfileArn"]
          instance_profile_name = instance_profile_arn[/instance-profile\/(.*)/,1]
          get_instance_profile = `aws iam get-instance-profile --instance-profile-name #{instance_profile_name}`
          return if get_instance_profile.blank?
          instance_profile = JSON.parse(get_instance_profile)
          return if instance_profile["InstanceProfile"]["Roles"].blank?
          instance_profile["InstanceProfile"]["Roles"].first["RoleName"]
        end
      end
    end
  end
end
