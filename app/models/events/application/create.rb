class Events::Application::Create < Event
  store_accessor :data

  belongs_to :application, class_name: '::Application', hstore: :data
  belongs_to :user,    hstore: :data
end
