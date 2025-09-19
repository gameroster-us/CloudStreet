# require 'spec_helper'
# 
# RSpec.describe Filer, :type => :model do
#   subject { described_class.new }
# 
#   it "should be enabled by default" do
#     expect(subject.enabled).to be_truthy
#   end
# 
#   it "should return true when enabled" do
#     expect(subject.is_enabled?).to be_truthy
#   end
# 
#   it "should return the generated script with arguments provided" do
#     args = {:session_user => "user@example.com", :session_password => "password", :we => "public_id", :endpoint => "192.168.10.23", :mount_ip => "12.12.12.12", :svm_name => "svm_name", :cifs_volume_count => 1, :nfs_volume_count => 1, :source_nfs => ["/mnt", "/mnt2"], :destination_nfs => ["/testbvol", "/testvol2"], :source_cifs => ["/samba", "/asdf"], :destination_cifs => ["samba", "asdf"], :netapp_nfs_volume_names => ["vol1", "vol2"], :netapp_cifs_username => "ausername", :netapp_cifs_password =>
#     "passworda"  }
#     str = "#!/bin/bash\n\nNETAPP_NO_VOLUME_NFS=\"1\" \nNETAPP_NO_VOLUME_CIFS=\"1\" \n\nNETAPP_NFS_VOLUME_NAMES=(\"vol1\" \"vol2\")\n\nNETAPP_SHARE_MOUNT_CIFS=(\"/samba\" \"/asdf\") #source_of_cifs\nNETAPP_MOUNTC_CIFS=(\"samba\" \"asdf\") #destination_of_cifs\n\n\nNETAPP_CIFS_USERNAME=\"ausername\"\nNETAPP_CIFS_PASSWORD=\"passworda\"\n\n\n\nNETAPP_MOUNTS_NFS=(\"/mnt\" \"/mnt2\")\n\nNETAPP_MOUNTC_NFS=(\"/testbvol\" \"/testvol2\")\n\n\n\nNETAPP_PROTOCOL_NFS=nfs #hardcode\nNETAPP_PROTOCOL_CIFS=cifs #hardcode\n\nNETAPP_MOUNT_IP=\"12.12.12.12\" #uniq\nNETAPP_FILESERVER=\"192.168.10.23\" #uniq\nNETAPP_WORKING_ENV=\"public_id\" #uniq\nNETAPP_SVM_NAME=\"svm_name\" #uniq\nNETAPP_SESSION_USER=\"user@example.com\" #uniq\nNETAPP_SESSION_PASS=\"password\" #uniq\nCURRENT_SERVER_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4) #uniq_dynamic\n\n\n"
#     expect(subject.generate_scripts(args)).to eq(str)
#   end
# 
#   it { should belong_to(:account) }
#   it { should belong_to(:cloud_resource_adapter) }
# 
#   it  {should have_many(:filer_volumes)}
#   it  {should have_many(:filer_configurations)}
#   it  {should have_many(:filer_services)}
#   it  {should have_many(:services)}
# 
#   it "should return only enabled filers and not return disabled filers" do
#     @filer_active = FactoryBot.create(:filer)
#     @filer_inactive = FactoryBot.create(:filer, enabled: false)
#     expect(Filer.active.count).to eq(1)
#     expect(Filer.active.first.id).to eq(@filer_active.id)
#     expect(Filer.active.first.id).not_to eq(@filer_inactive.id)
#   end
# 
# 
# end
