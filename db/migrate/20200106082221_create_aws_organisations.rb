class CreateAWSOrganisations < ActiveRecord::Migration[5.1]
  def change
    create_table :aws_organisations, id: :uuid do |t|
      t.string :organisation_id
      t.uuid   :adapter_id
      t.uuid   :account_id
      t.string :aws_account_id
      t.string :arn
      t.string :feature_set
      t.string :master_account_arn
      t.string :master_account_id
      t.string :master_account_email
      t.json   :available_policy_types

      t.timestamps
    end
  end
end