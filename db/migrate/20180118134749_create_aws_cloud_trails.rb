class CreateAWSCloudTrails < ActiveRecord::Migration[5.1]
  def change
    create_table :aws_cloud_trails, id: :uuid do |t|
      t.boolean :running
      t.uuid :adapter_id, index: true
      t.timestamp :last_trail_time
      t.timestamp :last_process_time
      t.timestamps
    end
  end
end
