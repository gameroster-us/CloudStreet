module PublicKeyRepresenter
  include Roar::JSON
  include Roar::Hypermedia

  property :id
  property :name
  property :key
  property :fingerprint

  link :self do
    key_path(id)
  end

  # link :remove do |args|
  #   key_path(id) if args[:options][:current_user].can_delete?(self)
  # end

  # link :edit do |args|
  #   key_path(id) if args[:options][:current_user].can_update?(self)
  # end
end
