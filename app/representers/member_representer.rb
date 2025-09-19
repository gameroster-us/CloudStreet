module MemberRepresenter
include Roar::JSON
include Roar::Hypermedia

  property :id
  property :username
  property :email
  property :unconfirmed_email
  property :name
  property :state
  property :created_at
  property :user_type
end
