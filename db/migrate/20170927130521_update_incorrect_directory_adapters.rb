class UpdateIncorrectDirectoryAdapters < ActiveRecord::Migration[5.1]
  def up
    Adapters::AWS.where(state: 'error', account_id: nil).update_all(state: 'directory')
  end

  def down

  end  
end
