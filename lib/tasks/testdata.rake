namespace :testdata do
  desc "Seed the data"
  task seed: :environment do
    TESTDATA = YAML.load_file(Rails.root.join('data', 'testdata.yml'))
    TESTDATA.each do |key, users|
        users.each do |user|
          user['organisation_name'] = key
          p "========#{user}"
          newuser = UserCreator.create_test_user(user)
          newuser.user_roles = []
          newuser.user_roles << newuser.account.roles.where(name: user['role'])
        end  
    end
  end 
end