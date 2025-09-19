class ChangeFieldsInServiceDetails < ActiveRecord::Migration[5.1]
	def up
  	add_column :service_details, :comment_type, :string
  	add_column :service_details, :user_email, :string
  	
  	remove_column :service_details, :comment, :string
  	remove_column :service_details, :commented_by, :string
  	remove_column :service_details, :commented_date, :datetime

  	rename_column :service_details, :ignored_comment, :comment
  	rename_column :service_details, :ignored_by, :commented_by
  	rename_column :service_details, :ignored_date, :commented_date

  	change_column :service_details, :comment, :text
	end
	
	def down
		remove_column :service_details, :comment_type, :string
		remove_column :service_details, :user_email, :string

		rename_column :service_details, :comment, :ignored_comment
  	rename_column :service_details, :commented_by, :ignored_by
  	rename_column :service_details, :commented_date, :ignored_date

		add_column :service_details, :comment, :string
		add_column :service_details, :commented_by, :string
		add_column :service_details, :commented_date, :datetime
		
	end
end
