class InstanceFiler

  attr_accessor :name, :properties, :generic_type, :type, :draggable, :drawable, :internal, :version, :filer_type, :account, :region, :user, :adapter

  
   def initialize(name, filer_type)
    @name = name
    @drawable = true
    @draggable = true
    @internal = true
    @version = "0.1.0"
    @filer_type = filer_type
    @generic_type = 'Services::Compute::Server::InstanceFiler'
   end


   ["depends", "provides", "container", "sink", "expose"].each do |method|
    define_method(method.to_sym) { [] }
  end

  def properties
    filer_protocol = self.name.split.first.downcase
    prop = [{
         name: 'filer_protocol',
         type: 'String',
         form_options: {
             type: "text",
             required: true
         },
         title: 'Filer Protocol',
         value:  filer_protocol || ""
     },
     {
         name: 'filer_id',
         type: 'String',
         form_options: {
             type: "text",
             required: true
         },
         title: 'Filer Id',
         value:  ''
     },
     {
         name: 'filer_volume_id',
         type: 'String',
         form_options: {
             type: "text",
             required: true
         },
         title: 'Filer Volume Id',
         value:  ''
     },
     {
         name: 'filer_configuration_id',
         type: 'String',
         form_options: {
             type: "text",
             required: true
         },
         title: 'Filer Configuration Id',
         value:  ''
     },
     {
         name: 'mount_ip',
         type: 'String',
         form_options: {
             type: "text",
             required: true
         },
         title: 'Mount IP',
         value:  ''
     },
     {
         name: 'source',
         type: 'String',
         form_options: {
             type: "text",
             required: true
         },
         title: 'Source',
         value:  ''
     },
     {
         name: 'destination',
         type: 'String',
         form_options: {
             type: "text",
             required: true
         },
         title: 'Destination',
         value:  ''
     },
     {
         name: 'size',
         type: 'String',
         form_options: {
             type: "text",
             required: true
         },
         title: 'Size',
         value:  ''
     }]


    prop += [{
         name: 'username',
         type: 'String',
         form_options: {
             type: "text",
             required: false
         },
         title: 'Username',
         value:  ''
     },
     {
         name: 'password',
         type: 'String',
         form_options: {
             type: "password",
             required: false
         },
         title: 'Password',
         value:  ''
     }]  if filer_protocol.eql?('cifs')
     prop
  end

end