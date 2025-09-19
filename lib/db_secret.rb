module DBSecret  
  require 'openssl'
  class << self
    def encrypt(data, key)
      cipher = OpenSSL::Cipher.new("aes-256-cbc")
      cipher.encrypt
      cipher.key = key = Digest::SHA256.digest(key)  
      cipher.iv = Digest::SHA256.digest(key).slice(0, 16)
      encrypted = cipher.update(data) 
      encrypted << cipher.final
      encoded = Base64.encode64(encrypted).encode('utf-8') 
      return encoded
    end

    def decrypt(data, key)
      cipher = OpenSSL::Cipher.new("aes-256-cbc")
      cipher.decrypt
      cipher.key = cipher_key = Digest::SHA256.digest(key)  
      decoded = Base64.decode64 data.encode('ascii-8bit') 
      cipher.iv = Digest::SHA256.digest(cipher_key).slice(0, 16)
      begin
        decrypted = cipher.update(decoded)
        decrypted << cipher.final 
      rescue OpenSSL::Cipher::CipherError, TypeError
        return "nil"
      end 
      return decrypted  
    end
  end 
end  	