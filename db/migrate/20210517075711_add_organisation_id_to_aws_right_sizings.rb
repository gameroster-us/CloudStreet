class AddOrganisationIdToAWSRightSizings < ActiveRecord::Migration[5.1]
  def change
    add_column :aws_right_sizings, :organisation_id, :string
  end
end
