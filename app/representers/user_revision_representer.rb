module UserRevisionRepresenter
include Roar::JSON
include Roar::Hypermedia

  property :id
  property :name
  property :username
  property :email
  
end
