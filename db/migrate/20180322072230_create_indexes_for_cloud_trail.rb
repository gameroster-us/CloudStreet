class CreateIndexesForCloudTrail < ActiveRecord::Migration[5.1]
  def up
    CloudTrailEvent.create_indexes
    CloudTrailEventLog.create_indexes
  end

  def down
    CloudTrailEvent.remove_indexes
    CloudTrailEventLog.remove_indexes
  end
end
