class AddErrorMessageToCSServices < ActiveRecord::Migration[5.1]
  def change
  	add_column :CS_services, :error_message, :text
  end
end
