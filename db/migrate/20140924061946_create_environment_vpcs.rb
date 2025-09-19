class CreateEnvironmentVpcs < ActiveRecord::Migration[5.1]
  def change
    create_table :environment_vpcs , id: :uuid  do |t|
      t.uuid :environment_id, index: true
      t.uuid :vpc_id, index: true		

      t.timestamps
    end
  end
end
