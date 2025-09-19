# require 'spec_helper'
# 
# describe Services::Database::Rds::AWS do
# 
#   describe ".get_cloudstreet_db_state" do
#     it "should return the state" do
#       state_hash = {
#         "creating" => "starting",
#         "backing-up" => "starting",
#         "modifying" => "modifying",
#         "available" => "running",
#         "deleting" => "terminating"
#       }
#       state_hash.keys.each do |state|
#         expect(subject.class.get_cloudstreet_db_state(state)).to eq state_hash[state]
#       end
#     end
#   end
#   describe '.format_attributes_by_raw_data' do
#     @keys = [
#       :name, :port, :db_name, :engine, :iops, :multi_az,
#       :password, :flavor_id, :license_model, :engine_version, :master_username,
#       :allocated_storage, :availability_zone, :publicly_accessible,
#       :backup_retention_period, :auto_minor_version_upgrade, :state,
#       :backup_window, :preferred_backup_window_duration, :preferred_backup_window_minute,
#       :preferred_backup_window_hour, :maintenance_window, :preferred_maintenance_window_duration,
#       :preferred_maintenance_window_minute, :preferred_maintenance_window_hour, :preferred_maintenance_window_day, :tags
#     ]
# 
#     @aws_service = FactoryBot.build(:fog_rds)
#     it_behaves_like "aws_attribute_formater", @aws_service, @keys
#   end
# 
#   describe '.service_ancestors' do
#     it 'should return ancestors array' do
#       ancestors = [Services::Vpc, Services::Network::SubnetGroup::AWS, Services::Network::SecurityGroup::AWS]
#       expect(subject.class.service_ancestors).to eql(ancestors)
#     end
#   end
# 
#   describe "validation methods" do
#     context "" do
#       before(:all) do
#         @postgres = Services::Database::Rds::AWS.new(name: 'PostgreSQL', data: { 'port' => 5432, 'engine' => 'postgres' })
#         @mysql = Services::Database::Rds::AWS.new(name: 'MySQL', data: { 'port' => 3306, 'engine' => 'mysql' })
#         @oracle_ee = Services::Database::Rds::AWS.new(name: 'Oracle Database Enterprise Edition', data: { 'port' => 1521, 'engine' => 'oracle-ee' })
#         @oracle_se = Services::Database::Rds::AWS.new(name: 'Oracle Database Standard Edition', data: { 'port' => 1521, 'engine' => 'oracle-se' })
#         @oracle_se1 = Services::Database::Rds::AWS.new(name: 'Oracle Database Standard Edition One', data: { 'port' => 1521, 'engine' => 'oracle-se1' })
#         @sqlserver_ee = Services::Database::Rds::AWS.new(name: 'SQL Server Enterprise Edition', data: { 'port' => 1433, 'engine' => 'sqlserver-ee' })
#         @sqlserver_se = Services::Database::Rds::AWS.new(name: 'SQL Server Standard Edition', data: {'port' => 1433, 'engine' => 'sqlserver-se'})
#         @sqlserver_ex = Services::Database::Rds::AWS.new(name: 'SQL Server Express Edition', data: {'port' => 1433, 'engine' => 'sqlserver-ex'})
#         @sqlserver_web = Services::Database::Rds::AWS.new(name: 'SQL Server Web Edition', data: {'port' => 1433, 'engine' => 'sqlserver-web'})
#         @aurora = Services::Database::Rds::AWS.new(name: 'Aurora - compatible with MySQL 5.6.10a', data: {'port' => 3306, 'engine' => 'aurora'})
#         @no_rds = Services::Database::Rds::AWS.new(name: 'No_Rds', data: {'port' => 0000, 'engine' => 'any_engine'})
#       end
#       describe ".find_max_storage" do
#         it "should return 1024 as max storage when engine is sqlserver ex" do
#           expect(@sqlserver_ex.find_max_storage).to eql(1024)
#         end
#         it "should return 1024 as max storage when engine is sqlserver web" do
#           expect(@sqlserver_se.find_max_storage).to eql(1024)
#         end
#         it "should return 1024 as max storage when engine is sqlserver ee" do
#           expect(@sqlserver_ee.find_max_storage).to eql(1024)
#         end
#         it "should return 1024 as max storage when engine is sqlserver se" do
#           expect(@sqlserver_web.find_max_storage).to eql(1024)
#         end
#         it "should return 3072 for other databases" do
#           expect(@oracle_ee.find_max_storage).to eql(3072)
#           expect(@oracle_se1.find_max_storage).to eql(3072)
#           expect(@oracle_se.find_max_storage).to eql(3072)
#           expect(@postgres.find_max_storage).to eql(3072)
#           expect(@mysql.find_max_storage).to eql(3072)
#           expect(@no_rds.find_max_storage).to eql(3072)
#           expect(@aurora.find_max_storage).to eql(3072)
#         end
#       end
#       describe ".find_min_storage" do
#         it "should return 200 as min_storege when engine is sqlserver-(ee or ex)" do
#           expect(@sqlserver_ee.find_min_storage).to eql(200)
#           expect(@sqlserver_se.find_min_storage).to eql(200)
#         end
#         it "should return 20 as min_storege when engine is sqlserver-(se or web)" do
#           expect(@sqlserver_ex.find_min_storage).to eql(20)
#           expect(@sqlserver_web.find_min_storage).to eql(20)
#         end
#         it "should return 10 as min_storege when engine is of any oracle server" do
#           expect(@oracle_se.find_min_storage).to eql(10)
#           expect(@oracle_ee.find_min_storage).to eql(10)
#           expect(@oracle_se1.find_min_storage).to eql(10)
#         end
#         it "should return 5 as min_storege when engine is postgres or mysql or any_rds" do
#           expect(@postgres.find_min_storage).to eql(5)
#           expect(@mysql.find_min_storage).to eql(5)
#           expect(@no_rds.find_min_storage).to eql(5)
#         end
#         it "should return 1 as min_storege when engine is aurora" do
#           expect(@aurora.find_min_storage).to eql(1)
#         end
#       end
#       describe ".available_license_model_options" do
#         it "should return general-public-license when mysql and aurora" do
#           expect(@mysql.available_license_model_options).to eq(['general-public-license'])
#           expect(@aurora.available_license_model_options).to eq(['general-public-license'])
#         end
#         it "should return postgresql-license when postgres" do
#           expect(@postgres.available_license_model_options).to eq(['postgresql-license'])
#         end
#         it "should return bring-your-own-license' and  'license-included' when  oracle_ee" do
#            expect(@oracle_ee.available_license_model_options).to eq(['bring-your-own-license'])
#         end
#         it "should return bring-your-own-license' and  'license-included' when oracle_se" do
#           expect(@oracle_se.available_license_model_options).to eq(['bring-your-own-license'])
#         end
#         it "should return bring-your-own-license' and  'license-included' when oracle_se1" do
#           expect(@oracle_se1.available_license_model_options).to eq(['bring-your-own-license', 'license-included'])
#         end
#         it "should return bring-your-own-license' and  'license-included' when sqlserver_ee" do
#           expect(@sqlserver_ee.available_license_model_options).to eq(["bring-your-own-license"])
#         end
#         it "should return bring-your-own-license' and  'license-included' when sqlserver_web" do
#           expect(@sqlserver_web.available_license_model_options).to eq(['license-included'])
#         end
#         it "should return bring-your-own-license' and  'license-included' when sqlserver_se" do
#           expect(@sqlserver_se.available_license_model_options).to eq(['bring-your-own-license', 'license-included'])
#         end
#         it "should return bring-your-own-license' and  'license-included' when sqlserver_ex" do
#           expect(@sqlserver_ex.available_license_model_options).to eq(['license-included'])
#         end
#         it "should return [] when the rds is not on the list" do
#           expect(@no_rds.available_license_model_options).to eq([])
#         end
#       end
#       describe "private method .server_img_path" do
#         it "should return rds-mysql when mysql" do
#           expect(@mysql.send(:server_img_path)).to eq('rds-mysql')
#         end
#         it "should return rds-postgres when postgres" do
#           expect(@postgres.send(:server_img_path)).to eq('rds-postgres')
#         end
#         it "should return rds-oracle when oracle-(se|se1|ee)" do
#           expect(@oracle_se1.send(:server_img_path)).to eq('rds-oracle')
#           expect(@oracle_se.send(:server_img_path)).to eq('rds-oracle')
#           expect(@oracle_ee.send(:server_img_path)).to eq('rds-oracle')
#         end
#         it "should return rds-sqlserver-ee when sqlserver-ee" do
#           expect(@sqlserver_ee.send(:server_img_path)).to eq('rds-sqlserver-ee')
#         end
#         it "should return rds-sqlserver-ex when sqlserver-ex" do
#           expect(@sqlserver_ex.send(:server_img_path)).to eq('rds-sqlserver-ex')
#         end
#         it "should return rds-sqlserver-se when sqlserver-se" do
#           expect(@sqlserver_se.send(:server_img_path)).to eq('rds-sqlserver-se')
#         end
#         it "should return rds-sqlserver-web when sqlserver-web" do
#           expect(@sqlserver_web.send(:server_img_path)).to eq('rds-sqlserver-web')
#         end
#         it "should return rds-aurora when aurora" do
#           expect(@aurora.send(:server_img_path)).to eq('rds-aurora')
#         end
#       end
#     end
#   end
# end
