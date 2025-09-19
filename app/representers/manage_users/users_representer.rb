# frozen_string_literal: false

module ManageUsers
  # ManageUsers::UsersRepresenter used in Manage users page
  module UsersRepresenter
    include Roar::JSON
    include Roar::Hypermedia
    include Roar::JSON::HAL

    property :total_records, getter: ->(args) { args[:options][:total_records] }

    collection(
      :users,
      class: User,
      extend: ManageUsers::UserRepresenter,
      embedded: true
    )

    def users
      collect
    end

    link :self do
      users_path
    end
  end
end
