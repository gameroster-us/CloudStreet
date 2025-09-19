class Filer < ApplicationRecord
  belongs_to :cloud_resource_adapter
  belongs_to :account
  has_many :filer_volumes, dependent: :destroy
  has_many :filer_configurations, dependent: :destroy
  has_many :aggregates
  has_many :storage_vms


  has_many :filer_services
  has_many :services, through: :filer_services


  scope :net_app_filers, -> { where(type: 'Filers::CloudResources::NetApp') }
  scope :filter_by_vpc_id, -> (vpc_id) { Filers::CloudResources::NetApp.active.eager_load(:filer_configurations).where('filer_configurations.vpc_id =? ', vpc_id) }
  scope :active, -> { where(enabled: true) }

  def is_enabled?
    self.enabled
  end

  def self.replace_variables(userdata, arguments)
    # {:session_user => cloud_adapter.email, :session_password => cloud_adapter.password, :we => server_filer.public_id, :endpoint => cloud_adapter_endpoint, :mount_ip => mount_ip, :svm_name => svm_name, :cifs_volume_count => cifs_volume_count, :nfs_volume_count => nfs_volume_count, :source_nfs => source_nfs, :destination_nfs => destination_nfs, :source_cifs => source_cifs, :destination_cifs => destination_cifs, :netapp_nfs_volume_names => netapp_nfs_volume_names, :netapp_cifs_username => netapp_cifs_username, :netapp_cifs_password => netapp_cifs_password  }
    replacement_hash = {
      "[NETAPP_NO_VOLUME]" => "(#{arguments[:cifs_volume_count]} #{arguments[:nfs_volume_count]})",
      "[NETAPP_SHARE_MOUNT_CIFS]" => "#{("(\'"+arguments[:source_cifs].join("\' \'")+"\')")}",
      "[NETAPP_MOUNTC_CIFS]" => "#{("(\'"+arguments[:destination_cifs].join("\' \'")+"\')")}",
      "[NETAPP_MOUNTS_NFS]" => "#{("(\'"+arguments[:source_nfs].join("\' \'")+"\')")}",
      "[NETAPP_MOUNTC_NFS]" => "#{("(\'"+arguments[:destination_nfs].join("\' \'")+"\')")}",
      "[NETAPP_PROTOCOL]" => "('cifs' 'nfs')",
      "[NETAPP_MOUNT_IP]" => "#{arguments[:mount_ip]}",
      "[NETAPP_CIFS_CREDENTIAL]" => "(\'#{arguments[:netapp_cifs_username]}\' \'#{arguments[:netapp_cifs_password]}\')"
    }

    parsed_userdata = userdata.gsub(/\[(.*?)\]/) { |m| replacement_hash[m] || m }
    parsed_userdata
  end  

  def wenv_type
    if self.working_environment_type.eql?('VSA') && self.data['is_ha']
      'aws/ha'
    elsif self.working_environment_type.eql?('VSA') && !self.data['is_ha']
      'vsa'
    elsif self.working_environment_type.eql?('ON_PREM')
      'onprem'
    else
      'azure'
    end
  end

  def get_url_params
    {
      wenv_type: self.working_environment_type,
      working_environment_id: self.public_id,
      cloud_provider_name: self.cloud_provider_name,
      is_ha: (self.data["is_ha"]|| false)
    }
  end

  def get_nfs_cifs_mount_ip
    if (self.data["ontap_cluster_properties"] && !self.data["ontap_cluster_properties"]["nodes"].blank?)
      self.data["ontap_cluster_properties"]["nodes"].first["lifs"].find{|logical_interface| 
        logical_interface["dataProtocols"].include?("nfs")
      }["ip"]
    else
      nil
    end
  rescue Exception => error
    nil
  end
end