class IamUserRolePolicy < ApplicationRecord

	belongs_to :iam_user
	belongs_to :iam_role
	belongs_to :policy

	scope :aws_account_iam_roles, -> (aws_account_id) { where(aws_account_id: aws_account_id, iam_type: "IamRole") }
	scope :aws_account_iam_users, -> (aws_account_id) { where(aws_account_id: aws_account_id, iam_type: "IamUser") }
end
