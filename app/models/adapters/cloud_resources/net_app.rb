require 'uri'
module Adapters
  module CloudResources
    class NetApp < CloudResourceAdapter

      store_accessor :credentials, :email, :password
      belongs_to :account

      validate :valid_endpoint
      validates_presence_of :endpoint, :email
      validate :format_of_endpoint


      def password
        AdapterSecret.decrypt(self.credentials['password'] ,CommonConstants::CloudStreet_KEY).to_s
      end

      def format_of_endpoint
        return unless self.new_record?
        self.errors[:endpoint] << ("#{self.endpoint} is invalid, please input the correct format of endpoint") unless (self.endpoint =~ URI::regexp(%w(http https))).eql?(0)
      end

      def valid_endpoint
        return unless self.new_record?
        adapters = self.class.where(account_id: self.account_id)
        endpoints = adapters.pluck(:endpoint)
        stripped_endpoints = endpoints.map {|s| s.gsub(/^(http|https):\/\//, '')}
        self.errors[:endpoint] << ("Adapter already created with this endpoint \'#{self.endpoint}\' , use different endpoint to create another adapter") if stripped_endpoints.include?(self.endpoint.gsub(/^(http|https):\/\//, ''))
      end

      def password=(password)
        self.credentials['password'] = AdapterSecret.encrypt(password, CommonConstants::CloudStreet_KEY)
        self.credentials_will_change!
      end
      
      def connection_verified?
        adapter_params = {
          endpoint: self.endpoint,
          email: self.email,
          password: self.password
        }
        agent = ProviderWrappers::NetAppAdapter.new(adapter_params)
        success, response = agent.login
        if success
          return true
        elsif !success && response.nil?
          self.errors[:endpoint] << "Could not connect to the endpoint"
        elsif !success && response.try(:body).try(:include?, "Incorrect email/password combination")
          self.errors[:email] << "Incorrect email/password combination"
        else
          self.errors[:endpoint] << "Could not connect to the endpoint"
        end
        return false
      end

    end
  end
end
