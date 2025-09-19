class AddAWSAccountIdColumnToMachineImageAndOrganisationImage < ActiveRecord::Migration[5.1]
  def change
    add_column :machine_images, :aws_account_id, :string, array: true, default: []
    add_column :organisation_images, :aws_account_id, :string, array: true, default: []
  end
end
