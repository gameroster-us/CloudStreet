module Private
  module UsersRepresenter
    include Roar::JSON
    include Roar::Hypermedia
    include Roar::JSON::HAL

    link :confirm do
      confirm_private_users_path
    end

    link :resend_confirmation do
      resend_confirmation_private_users_path
    end

    link :self do
      private_users_path
    end
  end
end
