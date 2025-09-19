module EncryptionKeysRepresenter
include Roar::JSON
include Roar::Hypermedia
include Roar::JSON::HAL

  property :total_records, getter: lambda { |args| args[:options][:total_records]}

  collection(
  :encryption_keys, 
  class: EncryptionKey,
  extend: EncryptionKeyRepresenter,
  embedded: true)


  def encryption_keys
    collect
  end
end