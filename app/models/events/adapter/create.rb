class Events::Adapter::Create < Event
  store_accessor :data

  belongs_to :adapter, class_name: '::Adapter', hstore: :data
  belongs_to :user,    hstore: :data
end
