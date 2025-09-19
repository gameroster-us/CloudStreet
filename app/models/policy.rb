class Policy < ApplicationRecord
	has_many :iam_user_role_policies
	has_many :iam_users, :through => :iam_user_role_policies ,  foreign_key: :iam_id
	has_many :iam_roles, :through => :iam_user_role_policies ,  foreign_key: :iam_id
end
