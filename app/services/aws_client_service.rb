class AWSClientService < ApplicationService
  class << self
    def method_missing(method_name, *args)
      if method_name.to_s.include?('errors')
        errors_class(method_name)
      else
        basic_connection(method_name, *args)
      end
    end

    def errors_class(method_name)
      type = method_name.to_s.sub('_errors', '')
      "Aws::#{type.to_s.camelize}::Errors::ServiceError".constantize
    end

    def basic_connection(type, region = nil, adapter = nil, instance_profile= false)
      access_credential = adapter ? adapter_credential(adapter) : default_credential(type)
      type = type.to_s.gsub('_OFFERING','')
      if instance_profile.eql?(true)
        return "Aws::#{type.to_s.camelize}::Client".constantize.new(
          region: region,
          credentials: Aws::InstanceProfileCredentials.new(retries: 3)
        )
      else
        access_credential.merge!({region: region, http_proxy: ENV['http_proxy']})
        return "Aws::#{type.to_s.camelize}::Client".constantize.new(access_credential)
      end
    end

    def default_credential(type)
      (type.to_s.include?('_OFFERING') ? 'RI_OFFERING' : 'DEFAULT_KEYS').constantize
    end

    def adapter_credential(adapter)
      response = {}
      if adapter.role_based?
        sts = Fog::AWS::STS.new(use_iam_profile: true, region: adapter.data['sts_region'])
        if adapter.data['external_id'].blank?
          sts_res = sts.assume_role(adapter.data["aws_account_id"], adapter.data["role_arn"])
        else
          sts_res = sts.assume_role(adapter.data["aws_account_id"], adapter.data["role_arn"], adapter.data['external_id'])
        end
        return {} if sts_res.body["AccessKeyId"].blank?
        response[:access_key_id] = sts_res.body["AccessKeyId"]
        response[:secret_access_key] = sts_res.body["SecretAccessKey"]
        response[:session_token] = sts_res.body["SessionToken"]
      else
        response[:access_key_id] = adapter.access_key_id
        response[:secret_access_key] = adapter.secret_access_key
      end
      response
    end
  end
end
