# frozen_string_literal: true

module ChildOrganisation
  module Reseller
    # Authorizing shared adapters' actions which are shared to child organisation.
    class AdapterAuthorizer < ApplicationAuthorizer
      def self.default(_adjective, _user)
        false
      end

      def self.updatable_by?(user, _args = {})
        user.is_permission_granted?('cs_reseller_child_organisation_shared_adapter_edit')
      end

    end
  end
end
