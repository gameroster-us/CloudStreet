# frozen_string_literal: true

module ChildOrganisation
  # Authorizing shared adapters' actions which are shared to child organisation.
  class AdapterAuthorizer < ApplicationAuthorizer
    def self.default(_adjective, _user)
      false
    end

    def self.updatable_by?(user, _args = {})
      user.is_permission_granted?('cs_child_organisation_shared_adapter_edit')
    end

    # def self.deletable_by?(user, _args = {})
    #   user.is_permission_granted?('cs_child_organisation_shared_adapter_delete')
    # end
  end
end
