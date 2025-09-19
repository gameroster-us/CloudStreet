require "awscosts/cache"
require 'addressable/uri'

AWSCosts::Cache.module_eval do

  def get uri, base_uri = AWSCosts::Cache::BASE_URI, &block
    options = {}
    if ENV["http_proxy"]
      proxy_uri = Addressable::URI.parse(ENV["http_proxy"])
      options.merge!({http_proxyaddr: proxy_uri.host,http_proxyport: proxy_uri.port})
      options.merge!({http_proxyuser: proxy_uri.user}) unless proxy_uri.user.nil?
      options.merge!({http_proxypass: proxy_uri.password}) unless proxy_uri.password.nil?
    end
    cache["#{base_uri}#{uri}"] ||= Oj::load.safe_load (HTTParty.get("#{base_uri}#{uri}", options).body)
    yield cache["#{base_uri}#{uri}"]
  end

  def get_jsonp uri, base_uri = AWSCosts::Cache::BASE_JSONP_URI, &block
    attempts = 0
    options = {}
    if ENV["http_proxy"]
      proxy_uri = Addressable::URI.parse(ENV["http_proxy"])
      options.merge!({http_proxyaddr: proxy_uri.host,http_proxyport: proxy_uri.port})
      options.merge!({http_proxyuser: proxy_uri.user}) unless proxy_uri.user.nil?
      options.merge!({http_proxypass: proxy_uri.password}) unless proxy_uri.password.nil?
    end

    cache["#{base_uri}#{uri}"] ||= begin
      extract_json_from_callback(HTTParty.get("#{base_uri}#{uri}", options).body)
    rescue NoMethodError
      attempts += 1
      retry if attempts < 5
      raise "Failed to retrieve or parse data for #{base_uri}#{uri}"
    end

    yield cache["#{base_uri}#{uri}"]
  end

end
