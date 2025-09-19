module Fog
  module AWS
    class Compute
      class DescribeSecurityGroupsReal
        require "#{Rails.root}/lib/fog/parsers/aws/compute/describe_security_groups"
        # Describe all or specified security groups
        #
        # ==== Parameters
        # * filters<~Hash> - List of filters to limit results with
        #
        # === Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'securityGroupInfo'<~Array>:
        #       * 'groupDescription'<~String> - Description of security group
        #       * 'groupId'<~String> - ID of the security group.
        #       * 'groupName'<~String> - Name of security group
        #       * 'ipPermissions'<~Array>:
        #         * 'fromPort'<~Integer> - Start of port range (or -1 for ICMP wildcard)
        #         * 'groups'<~Array>:
        #           * 'groupName'<~String> - Name of security group
        #           * 'userId'<~String> - AWS User Id of account
        #         * 'ipProtocol'<~String> - Ip protocol, must be in ['tcp', 'udp', 'icmp']
        #         * 'ipRanges'<~Array>:
        #           * 'cidrIp'<~String> - CIDR range
        #            * 'descrption' <~String>
        #         * 'toPort'<~Integer> - End of port range (or -1 for ICMP wildcard)
        #       * 'ownerId'<~String> - AWS Access Key Id of the owner of the security group
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSecurityGroups.html]
        def describe_security_groups(filters = {})
          unless filters.is_a?(Hash)
            Fog::Logger.deprecation("describe_security_groups with #{filters.class} param is deprecated, use describe_security_groups('group-name' => []) instead [light_black](#{caller.first})[/]")
            filters = {'group-name' => [*filters]}
          end
          params = Fog::AWS.indexed_filters(filters)
          request({
            'Action'    => 'DescribeSecurityGroups',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::Compute::DescribeSecurityGroups.new
          }.merge!(params))
        end
      end
    end
  end
end
