class AddErrorToServices < ActiveRecord::Migration[5.1]
  def change
  	add_column :services, :error_message, :text
  end
end
