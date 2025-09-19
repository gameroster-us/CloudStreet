module GroupRoleRepresenter
include Roar::JSON
include Roar::Hypermedia

  # Assumed that for now we have one account per group, so we don't need any other details
  property :name
end
