namespace :user_role do
  desc "Backing up Dynamo DB"
  task add_basic_role: :environment do
    Account.all.each do |account|
      user_role = UserRole.find_by(:name=>'Basic',account_id: account.id)
      unless user_role
        basic_role = UserRole.create(:name=>'Basic',account_id: account.id)
        # role = Settings.default_roles
        # rights = role.Basic.collect do |code|
        #   AccessRight.find_by_code(code)
        # end
        # user_role.rights<<rights.compact
      end
    end
  end
end
  
