class CreateAzureComplianceStandards < ActiveRecord::Migration[5.1]
  def change
    create_table :azure_compliance_standards, id: :uuid do |t|
      t.string :standard_type
      t.string :standard_version
      t.timestamps
    end
  end
end
