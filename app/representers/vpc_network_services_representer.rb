module VpcNetworkServicesRepresenter
include Roar::JSON
include Roar::Hypermedia

  property :nacl, extend: NetworkAclRepresenter
  collection(
    :existing_subnets,
    class: Subnet,
    extend: Subnets::SubnetRepresenter)
  collection(
    :existing_security_groups,
    class: SecurityGroups::AWS,
    extend: SecurityGroups::SecurityGroupRepresenter)
  collection(
    :existing_subnet_groups,
    class: SubnetGroups::AWS,
    extend: SubnetGroups::SubnetGroupRepresenter)
end
