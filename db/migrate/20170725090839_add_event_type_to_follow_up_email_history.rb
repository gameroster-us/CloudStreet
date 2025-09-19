class AddEventTypeToFollowUpEmailHistory < ActiveRecord::Migration[5.1]
  def change
    add_column :follow_up_email_histories, :event_type, :string
  end
end
