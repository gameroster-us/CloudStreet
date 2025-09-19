module Fog
  module AWS
    class Rds
      class CopyDBSnapshotMock
        #
        # Usage
        #
        # Fog::AWS[:rds].copy_db_snapshot("snap-original-id", "snap-backup-id", true)
        #

        def copy_db_snapshot(source_db_snapshot_identifier, target_db_snapshot_identifier, copy_tags = false,kms_key_id = nil)
          response = Excon::Response.new
          response.status = 200
          snapshot_id = Fog::AWS::Mock.snapshot_id
          data = {
            'snapshotId'  => snapshot_id,
          }
          self.data[:snapshots][snapshot_id] = data
          response.body = {
            'requestId' => Fog::AWS::Mock.request_id
          }.merge!(data)
          response
        end
      end
    end
  end
end