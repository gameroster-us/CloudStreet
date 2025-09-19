class Resources::PublicKey < Resource
  store_accessor :data, :key, :fingerprint
end
