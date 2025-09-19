class Adapters::Heroku < Adapter
  @permits = [:username, :password]

  store_accessor :data, :username, :password

  # state_machine do
  #   state :pending do
  #     validates_presence_of :username
  #     validates_presence_of :password
  #   end
  # end

  def attrs
    [{
      name: 'username',
      type: 'String',
      title: 'Username',
      text: 'Heroku username',
      validation: '/[a-zA-Z]/'
    }, {
      name: 'password',
      type: 'String',
      title: 'Password',
      text: 'Heroku Password',
      validation: '/[a-zA-Z]/'
    }]
  end

  def info
    username
  end
end
