class AddAccountIdToAWSMarketplaceSaasSubscription < ActiveRecord::Migration[5.2]
  def change
    add_column :aws_marketplace_saas_subscriptions, :customer_aws_account_id, :string
  end
end
