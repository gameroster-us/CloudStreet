class CreateAWSMarketplaceSaasSubscriptions < ActiveRecord::Migration[5.1]
  def change
    create_table :aws_marketplace_saas_subscriptions, id: :uuid do |t|
      t.string :customer_identifier
      t.string :status
      t.datetime :subscription_date
      t.boolean :active, default: false

      t.timestamps
    end
  end
end
