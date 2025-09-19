class UpdateIncorrectDirectoryAdaptersv1 < ActiveRecord::Migration[5.1]
  def up
    Adapters::AWS.where(state: 'error', account_id: nil).update_all(state: 'directory')
    system('rm amifetch-*')
  end

  def down

  end
end
