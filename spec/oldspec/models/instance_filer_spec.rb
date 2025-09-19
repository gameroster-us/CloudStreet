# require 'spec_helper'
# 
# RSpec.describe InstanceFiler, :type => :model do
#   # ['NFS', 'CIFS'].each do |filer_volume_type|
#   #   filer_objects << InstanceFiler.new("#{filer_volume_type} volume", filer_volume_type)
#   # end
# 
#   context "InstanceFiler" do
#     before(:all) do
#       @nfs_filer =  InstanceFiler.new("NFS volume", 'NFS')
#       @cifs_filer =  InstanceFiler.new("CIFS volume", 'CIFS')
#     end
#     describe "Instance filers should have the attributes on initialization" do
#       it "should throw ArgumentError when initalised without arguments" do
#         expect { InstanceFiler.new }.to raise_error(ArgumentError)
#       end
# 
#       it "should have the required attributes on initialization" do
#         ['name', 'drawable', 'draggable', 'internal', 'version', 'filer_type', 'generic_type'].each do |arg|
#           expect(@nfs_filer.send(arg.to_sym)).to be_truthy
#         end
#       end
# 
#       it "should return [] when attributes accessed" do
#         ["depends", "provides", "container", "sink", "expose"].each do |arg|
#           expect(@nfs_filer.send(arg.to_sym)).to eq([])
#         end
#       end
# 
#       it "should have specified properties for nfs" do
#         expect(@nfs_filer.properties.collect {|prop| prop[:name]}).to eq(["filer_protocol", "filer_id", "filer_volume_id", "filer_configuration_id", "mount_ip", "source", "destination"])
#       end
#       it "shoud not include username and password for nfs properties" do
#         expect(@nfs_filer.properties.collect {|prop| prop[:name]}).not_to include(['username', 'password'])
#       end
#       it "should have specified properties for cifs" do
#         expect(@cifs_filer.properties.collect {|prop| prop[:name]}).to eq(["filer_protocol", "filer_id", "filer_volume_id", "filer_configuration_id", "mount_ip", "source", "destination", "username", "password"])
#       end
#     end
#   end
# end
