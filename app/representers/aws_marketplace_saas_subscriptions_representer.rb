module AWSMarketplaceSaasSubscriptionsRepresenter
  include Roar::JSON
  include Roar::Hypermedia

  property :saas_subscriptions_url
  property :payment_access_right, getter: lambda {|args| args[:options][:payment_access_right]}
  collection(
    :saas_subscriptions,
    extend: AWSMarketplaceSaasSubscriptionRepresenter)

  def saas_subscriptions
    collect
  end

  def saas_subscriptions_url
    CommonConstants::SAAS_PRODUCT_URL
  end
end