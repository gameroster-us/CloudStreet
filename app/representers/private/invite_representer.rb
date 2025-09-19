module Private
  module InviteRepresenter
    include Roar::JSON
    include Roar::Hypermedia

    property :unconfirmed_email
#    property :user_id
#    property :account_id
    # link :self do
    #   private_invite_path #(id)
    # end
  end
end
