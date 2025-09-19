class Services::Compute::KeyPair < Service
  store_accessor :data, :key, :public_key, :fingerprint, :name, :private_key
  include Services::ServiceHelpers::AWS

  def self.create_pair(ref_id,account_id)
    key = OpenSSL::PKey::RSA.new 2048

    type = "ssh-rsa" # key.ssh_type

    cipher =  OpenSSL::Cipher.new("aes-256-cbc")

    # FIXME: Security, make configurable and external
    private_key = key.to_pem(cipher, 'password')
    CSLogger.info "Private key: #{private_key}"

    data = [ key.export(cipher, 'password') ].pack('m0')
    openssh_format = "#{type} #{data}"

    pair = self.new(name: "key-#{ref_id}",account: account_id, key: private_key, public_key: openssh_format)
    pair.save!
    pair
  end

  def self.create(options)
    region  = Region.find(options["region_id"])
    adapter = Adapter.find(options["adapter_id"])
    key_compute_agent = ProviderWrappers::AWS.compute_agent(adapter, region.code)
    wrapper = ProviderWrappers::AWS::Computes::AWSKeyPair.new(service: nil, agent: key_compute_agent)
    key_pair = wrapper.get_key_pair(options["key_name"])
    if key_pair.present?
      Resources::KeyPair.create({
        name: options["key_name"],
        data: load_key_pair_data(key_pair),
        region: region,
        adapter: adapter,
        account_id: options["account_id"],
        user_role_ids: []
      })
    end
  end

  def self.load_key_pair_data(key_pair)
    {
      "name" => key_pair.name,
      "fingerprint" => key_pair.fingerprint,
      "key" => key_pair.private_key||"",
      "save" => false,
      "user_role_ids" => []
    }
  end
end
