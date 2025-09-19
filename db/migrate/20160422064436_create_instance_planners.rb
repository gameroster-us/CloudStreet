class CreateInstancePlanners < ActiveRecord::Migration[5.1]
  def change
    create_table :instance_planners, id: :uuid do |t|
      t.uuid :account_id
      t.uuid :region_id
      t.uuid :adapter_id
      t.integer :total_instances
      t.integer :active_standard
      t.integer :active_scheduled
      t.integer :unused_standard
      t.integer :unused_scheduled
      t.integer :ec2_covered
      t.integer :ec2_uncovered
      t.float :potential_benifit
      t.json :data

      t.timestamps
    end
  end
end
