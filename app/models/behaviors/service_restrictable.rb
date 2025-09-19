module Behaviors::ServiceRestrictable
  def self.included(klass)
    klass.extend ClassMethods
  end

  def has_access?(role_ids = [])
    ((role_ids & user_role_ids) != []) unless user_role_ids.nil?
  end

  module ClassMethods
    def user_accessible_params(user, account)
      role_ids = user.get_user_role_ids
      accessible_param_array = []
      included_class = ancestors.first

      account.send(included_class::ACCESSIBLE_PARAM).each do |param|
        if param.has_access?(role_ids)
          accessible_param_array << param.id
        elsif param.user_role_ids == []
          accessible_param_array << param.id
        end
      end
      included_class.send(:find_accessible_params, accessible_param_array)
    end

    def invited_user_accessible_params(user, account)
      role_ids = user.get_user_role_ids
      accessible_param_array = []
      included_class = ancestors.first

      account.send(included_class::ACCESSIBLE_PARAM).each do |param|
        if param.has_access?(role_ids)
          accessible_param_array << param.id
        elsif param.user_role_ids == []
          accessible_param_array << param.id
        end
      end
      included_class.send(:find_accessible_params, accessible_param_array)
    end
  end
end
