class ProviderWrappers::AWS < ProviderWrapper
  attr_reader :agent, :service

  def initialize(service: nil, agent:)
    @agent   = agent
    @service = service if service
  end

  class << self

    def s3_agent(adapter, region_code = nil)
      attributes = connection_attributes(adapter, region_code)
      attributes.merge!(provider: 'AWS')
      ::Fog::Storage.new(attributes)
    end

    def compute_agent(adapter ,region_code = nil)
      attributes = connection_attributes(adapter, region_code)
      attributes.merge!(provider: 'AWS')
      ::Fog::Compute.new(attributes)
    end

    def rds_agent(adapter ,region_code)
      attributes = connection_attributes(adapter, region_code)
      Fog::AWS::RDS.new(attributes)
    end

    def kms_agent(adapter ,region_code)
      attributes = connection_attributes(adapter, region_code)
      Fog::AWS::KMS.new(attributes)
    end

    def elb_agent(adapter ,region_code)
      attributes = connection_attributes(adapter, region_code)
      Fog::AWS::ELB.new(attributes)
    end

    def autoscalling_agent(adapter, region_code)
      attributes = connection_attributes(adapter, region_code)
      Fog::AWS::AutoScaling.new(attributes)
    end

    def storage_agent(adapter, region_code)
      attributes = connection_attributes(adapter, region_code)
      attributes.merge!(provider: 'AWS')
      Fog::Storage.new(attributes)
    end

    def cloudwatch_agent(adapter, region_code)
      attributes = connection_attributes(adapter, region_code)
      ::Fog::AWS::CloudWatch.new(attributes)
    end

    def sns_agent(adapter, region_code = nil)
      attributes = connection_attributes(adapter, region_code)
      ::Fog::AWS::SNS.new(attributes)
    end

    def template_cost_agent(region_code)
       AWSCosts.region region_code     
    end

    def cloud_trail_agent(adapter, region_code)
      attributes = connection_attributes(adapter, region_code)
      if attributes.has_key?(:aws_session_token)
        credentials = Aws::Credentials.new(attributes[:aws_access_key_id],attributes[:aws_secret_access_key],attributes[:aws_session_token])
      else
        credentials = Aws::Credentials.new(attributes[:aws_access_key_id],attributes[:aws_secret_access_key])
      end
      Aws::CloudTrail::Client.new(region: region_code, credentials: credentials)
    end

    def connection_attributes(adapter, region_code = nil)
      attributes = {}
      if adapter.data && adapter.data["role_arn"].present?
        attributes.merge!(adapter.get_sts_connection_credentials)
      else
        attributes.merge!({
          aws_access_key_id: adapter.access_key_id,
          aws_secret_access_key: adapter.secret_access_key
        })
      end
      attributes.merge!(region: region_code) if region_code
      attributes
    end

    def get_aws_helper_account_credentials
      role_arn = "arn:aws:iam::068706686347:role/aws-public-data-access"
      get_instance_profile_attributes(role_arn)
    end

    def get_aws_helper_account_credentials_for_us_gov
      role_arn = "arn:aws-us-gov:iam::470830474521:role/aws-public-data-access"
      get_instance_profile_attributes_for_us_gov(role_arn)
    end

    def get_instance_profile_attributes(role_arn = nil, external_id = nil)
      aws_account_id = role_arn.match('^arn:aws:iam::([0-9]{12}):.*$').try(:[],1) if role_arn.present?
      sts = Fog::AWS::STS.new(aws_access_key_id: ENV["STS_AWS_ACCESS_KEY_ID"], aws_secret_access_key: ENV["STS_SECRET_ACCESS_KEY"])
      sts_credentionals_fetcher(sts, role_arn, aws_account_id, external_id)
    end

    def get_instance_profile_attributes_for_us_gov(role_arn = nil, external_id = nil)
      aws_account_id = role_arn.match('^arn:aws-us-gov:iam::([0-9]{12}):.*$').try(:[],1) if role_arn.present?
      sts = Fog::AWS::STS.new(aws_access_key_id: ENV["STS_US_GOV_AWS_ACCESS_KEY_ID"], aws_secret_access_key: ENV["STS_US_GOV_AWS_SECRET_ACCESS_KEY"], region: 'us-gov-east-1')
      sts_credentionals_fetcher(sts, role_arn, aws_account_id, external_id)
    end

    def sts_credentionals_fetcher(sts, role_arn, aws_account_id, external_id = nil)
      credentials = {}
      if role_arn.present? && aws_account_id.present?
        sts_res = sts.assume_role(aws_account_id, role_arn, external_id)
        if sts_res.status == 200
          credentials = {"AccessKeyId" => sts_res.body["AccessKeyId"],
                          "SecretAccessKey" => sts_res.body["SecretAccessKey"],
                          "SessionToken" => sts_res.body["SessionToken"],
                          "Expiration" => sts_res.body["Expiration"]}
        end
      else
        sts = Fog::AWS::STS.new(:use_iam_profile => true)
        if sts.instance_variable_get(:@use_iam_profile) == true
          credentials = {"AccessKeyId" => sts.instance_variable_get(:@aws_access_key_id),
                          "SecretAccessKey" => sts.instance_variable_get(:@aws_secret_access_key),
                          "SessionToken" => sts.instance_variable_get(:@aws_session_token),
                          "Expiration" => sts.instance_variable_get(:@aws_credentials_expire_at)}
        end
      end
      credentials.transform_keys! { |key| "aws_#{key.underscore}".to_sym }
      credentials.merge!({:provider=>'AWS'})
      return credentials
    end

    def parse_remote_service(remote_service)
      return remote_service if remote_service.blank?
      json_service = remote_service.to_json
      (!remote_service.blank? && json_service.is_a?(String)) ? JSON.parse(json_service) : remote_service
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
