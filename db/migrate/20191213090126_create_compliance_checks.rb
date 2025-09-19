class CreateComplianceChecks < ActiveRecord::Migration[5.1]
  def change
    create_table :compliance_checks, id: :uuid do |t|
      t.uuid :compliance_standard_id
      t.string :check_id
      t.string :check_section
      t.string :check_sub_section
      t.text :check_rule
      t.string :check_type
      t.boolean :check_automated, default: false
      t.text :check_CS_ids, array: true, default: []

      t.timestamps
    end
    add_foreign_key :compliance_checks, :compliance_standards, on_delete: :cascade
    add_index :compliance_checks, :compliance_standard_id
  end
end
