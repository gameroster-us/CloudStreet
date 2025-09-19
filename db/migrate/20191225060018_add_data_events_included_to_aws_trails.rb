class AddDataEventsIncludedToAWSTrails < ActiveRecord::Migration[5.1]
  def change
    add_column :aws_trails, :data_events_included, :boolean, default: true
  end
end
