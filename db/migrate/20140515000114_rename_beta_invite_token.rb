class RenameBetaInviteToken < ActiveRecord::Migration[5.1]
  def change
    return unless User.table_exists?
    rename_column :users, :beta_invite_token, :invite_token
  end
end
