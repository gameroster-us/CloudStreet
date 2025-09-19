module AccessRightRepresenter
  include Roar::JSON
  include Roar::Hypermedia

  property :id
  property :title
  property :code
  property :accessible
end
