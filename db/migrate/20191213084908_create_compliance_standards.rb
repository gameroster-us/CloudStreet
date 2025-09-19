class CreateComplianceStandards < ActiveRecord::Migration[5.1]
  def change
    create_table :compliance_standards, id: :uuid do |t|
      t.string :standard_type
      t.string :standard_version

      t.timestamps
    end
  end
end
