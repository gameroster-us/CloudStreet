class CreateAzureComplianceChecks < ActiveRecord::Migration[5.1]
  def change
    create_table :azure_compliance_checks, id: :uuid do |t|
      t.uuid   :azure_compliance_standard_id
      t.string :check_id
      t.string :check_section
      t.string :check_sub_section
      t.text :check_rule
      t.text :description
      t.string :check_type
      t.string :file_name
      t.timestamps
    end
    add_foreign_key :azure_compliance_checks, :azure_compliance_standards, on_delete: :cascade
    add_index :azure_compliance_checks, :azure_compliance_standard_id
  end
end
