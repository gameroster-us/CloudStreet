class CreateMachineImageConfiguration < ActiveRecord::Migration[5.1]
  def change
    create_table :machine_image_configurations, id: :uuid  do |t|
	  t.integer :organisation_image_id
	  t.string :name
      t.string :userdata
      t.uuid :user_role_ids, array: true, default: []

      t.timestamps
    end
  end
end
