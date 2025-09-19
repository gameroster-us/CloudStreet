class CreateAzureCompliancePolicies < ActiveRecord::Migration[5.1]
  def change
    create_table :azure_compliance_policies, id: :uuid do |t|
      t.uuid   :azure_compliance_check_id
      t.string :display_name
      t.text   :description
      t.string :name
      t.string :policy_id
      t.timestamps
    end
  end
end
