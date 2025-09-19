class Services::Compute::Server::IscsiVolume < Service

    store_accessor :data, :size, :target, :volume_type, :username, :password, :server_id, :target_ip

  VOLUME_TYPES = { 'iscsi' => 'Internet Small Computer System Interface (iSCSI)'}

  def provides
    [
      { name: "iscsivolume", protocol: Protocols::IscsiVolume }
    ]
  end

  def internal
    true
  end

  def properties
    [
     #    {
     #     name: 'size',
     #     type: 'Integer',
     #     form_options: {
     #         type: "range",
     #         min: 1,
     #         max: 1024,
     #         step: 1
     #     },
     #     title: 'Size',
     #     value: size || 4,
     #     validation: '/[1-1024]/'
     # }, 
     
      {
         name: 'target_ip',
         type: 'String',
         form_options: {
             type: "text"
         },
         title: 'Target Ip',
         value: target_ip || ''
     },
     {
         name: 'target',
         type: 'String',
         form_options: {
             type: "text"
         },
         title: 'Target',
         value: target || ''
     }, 
     # {
     #     name: 'volume_type',
     #     type: 'String',
     #     form_options: {
     #         type: "select",
     #         options: VOLUME_TYPES.values
     #     },
     #     title: 'Type',
     #     value: VOLUME_TYPES[volume_type] || VOLUME_TYPES.values.last
     # },

     {
         name: 'username',
         type: 'String',
         form_options: {
             type: "text"
         },
         title: 'Username',
         value: username || ''
     },{
            name: 'password',
            type: 'String',
            form_options: {
                type: "password"
            },
            title: 'Password',
            value: password || ''
        }]
  end

  def parent_services
    []
  end

  def object_restricted?
    false
  end
end
