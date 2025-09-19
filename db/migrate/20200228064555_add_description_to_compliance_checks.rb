class AddDescriptionToComplianceChecks < ActiveRecord::Migration[5.1]
  def change
    add_column :compliance_checks, :description, :text
  end
end
