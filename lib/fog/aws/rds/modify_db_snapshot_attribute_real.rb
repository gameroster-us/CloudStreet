module Fog
  module AWS
    class Rds
      class ModifyDBSnapshotAttributeReal
        require 'fog/aws/parsers/rds/modify_db_snapshot_attribute'

        # Modify db snapshot attributes
        #
        # ==== Parameters
        # * db_snapshot_identifier<~String> - Id of snapshot to modify
        # * attributes<~Hash>:
        #   * 'Add.MemberId'<~Array> - One or more account ids to grant rds create permission to
        #   * 'Remove.MemberId'<~Array> - One or more account ids to revoke rds create permission from
        #
        # {Amazon API Reference}[http://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_ModifyDBSnapshotAttribute.html]
        #
        def modify_db_snapshot_attribute(db_snapshot_identifier, attributes)
          params = {}
          params.merge!(Fog::AWS.indexed_param('ValuesToAdd.member.%d', attributes['Add.MemberId'] || []))
          params.merge!(Fog::AWS.indexed_param('ValuesToRemove.member.%d', attributes['Remove.MemberId'] || []))
          request({
            'Action'        => 'ModifyDBSnapshotAttribute',
            'DBSnapshotIdentifier'    => db_snapshot_identifier,
            :idempotent     => true,
            'AttributeName' => "restore",
            :parser         => Fog::Parsers::AWS::RDS::ModifyDbSnapshotAttribute.new
          }.merge!(params))
        end
      end
    end
  end
end