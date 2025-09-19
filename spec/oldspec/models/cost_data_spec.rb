# require 'spec_helper'
# 
# describe CostData do
#   before(:all) do
#     @account = FactoryBot.create(:account, :with_user)
#     @dev_adapter = FactoryBot.create(:adapter, :aws, account: @account)
#     @test_adapter = FactoryBot.create(:adapter, :aws, account: @account)
#     @environment = FactoryBot.create(:environment, :for_region_sa_east_1, account: @account, default_adapter: @dev_adapter)
#     @sao_paulo_region = @environment.region
#     @service = FactoryBot.create(:service, :volume_aws, :running, account: @account, region: @sao_paulo_region, adapter: @dev_adapter, environment: @environment, data: '{"size":10,"volume_type":"Magnetic","iops":100,"device":"/dev/sda1","root_device":true,"attach_status":"detached","status":"deleted"}')
#     @template_data = TemplateCost.create(:region_id => @sao_paulo_region.id, :data => '{"sa-east-1":{"ec2":{"on_demand":{"linux":{"t2.micro":0.027,"t2.small":0.054,"t2.medium":0.108,"t2.large":0.216,"m3.medium":0.095,"m3.large":0.19,"m3.xlarge":0.381,"m3.2xlarge":0.761,"c3.large":0.163,"c3.xlarge":0.325,"c3.2xlarge":0.65,"c3.4xlarge":1.3,"c3.8xlarge":2.6,"r3.4xlarge":2.946,"r3.8xlarge":5.892,"m1.small":0.058,"m1.medium":0.117,"m1.large":0.233,"m1.xlarge":0.467,"c1.medium":0.179,"c1.xlarge":0.718,"m2.xlarge":0.323,"m2.2xlarge":0.645,"m2.4xlarge":1.291,"t1.micro":0.027},"windows":{"t2.micro":0.032,"t2.small":0.064,"t2.medium":0.128,"t2.large":0.246,"m3.medium":0.158,"m3.large":0.316,"m3.xlarge":0.633,"m3.2xlarge":1.265,"c3.large":0.246,"c3.xlarge":0.491,"c3.2xlarge":0.982,"c3.4xlarge":1.964,"c3.8xlarge":3.928,"r3.4xlarge":3.394,"r3.8xlarge":6.788,"m1.small":0.089,"m1.medium":0.179,"m1.large":0.357,"m1.xlarge":0.715,"c1.medium":0.259,"c1.xlarge":1.038,"m2.xlarge":0.423,"m2.2xlarge":0.845,"m2.4xlarge":1.691,"t1.micro":0.037},"windows_with_sql":{"m3.medium":0.419,"m3.large":0.837,"m3.xlarge":1.507,"m3.2xlarge":3.013,"c3.xlarge":1.294,"c3.2xlarge":2.587,"c3.4xlarge":5.174,"c3.8xlarge":10.347,"r3.4xlarge":6.582,"r3.8xlarge":15.631,"m1.small":0.664,"m1.medium":0.814,"m1.large":1.092,"m1.xlarge":1.628,"c1.xlarge":2.378,"m2.xlarge":1.314,"m2.2xlarge":1.903,"m2.4xlarge":3.804},"windows_with_sql_web":{"t2.micro":0.077,"t2.small":0.164,"t2.medium":0.328,"t2.large":0.546,"m3.medium":0.235,"m3.large":0.469,"m3.xlarge":0.939,"m3.2xlarge":1.877,"c3.large":0.329,"c3.xlarge":0.657,"c3.2xlarge":1.313,"c3.4xlarge":2.626,"c3.8xlarge":5.252,"r3.4xlarge":3.786,"r3.8xlarge":8.052,"m1.small":0.168,"m1.medium":0.297,"m1.large":0.553,"m1.xlarge":1.067,"c1.medium":0.369,"c1.xlarge":1.398,"m2.xlarge":0.623,"m2.2xlarge":1.205,"m2.4xlarge":2.411,"t1.micro":0.077},"rhel":{"t2.micro":0.087,"t2.small":0.114,"t2.medium":0.168,"t2.large":0.276,"m3.medium":0.155,"m3.large":0.25,"m3.xlarge":0.441,"m3.2xlarge":0.891,"c3.large":0.223,"c3.xlarge":0.385,"c3.2xlarge":0.78,"c3.4xlarge":1.43,"c3.8xlarge":2.73,"r3.4xlarge":3.076,"r3.8xlarge":6.022,"m1.small":0.118,"m1.medium":0.177,"m1.large":0.293,"m1.xlarge":0.527,"c1.medium":0.239,"c1.xlarge":0.848,"m2.xlarge":0.383,"m2.2xlarge":0.705,"m2.4xlarge":1.421,"t1.micro":0.087},"sles":{"t2.micro":0.037,"t2.small":0.084,"t2.medium":0.208,"t2.large":0.316,"m3.medium":0.195,"m3.large":0.29,"m3.xlarge":0.481,"m3.2xlarge":0.861,"c3.large":0.263,"c3.xlarge":0.425,"c3.2xlarge":0.75,"c3.4xlarge":1.4,"c3.8xlarge":2.7,"r3.4xlarge":3.046,"r3.8xlarge":5.992,"m1.small":0.088,"m1.medium":0.217,"m1.large":0.333,"m1.xlarge":0.567,"c1.medium":0.279,"c1.xlarge":0.818,"m2.xlarge":0.423,"m2.2xlarge":0.745,"m2.4xlarge":1.391,"t1.micro":0.037}}},"ec2_ebs":[{"name":"Amazon EBS General Purpose (SSD) volumes","values":[{"prices":{"USD":"0.19"},"rate":"perGBmoProvStorage"}]},{"name":"Amazon EBS Provisioned IOPS (SSD) volumes","values":[{"prices":{"USD":"0.238"},"rate":"perGBmoProvStorage"},{"prices":{"USD":"0.091"},"rate":"perPIOPSreq"}]},{"name":"Amazon EBS Magnetic volumes","values":[{"prices":{"USD":"0.12"},"rate":"perGBmoProvStorage"},{"prices":{"USD":"0.12"},"rate":"perMMIOreq"}]},{"name":"ebsSnapsToS3","values":[{"prices":{"USD":"0.13"},"rate":"perGBmoDataStored"}]}],"elastic_ips":{"oneEIP":0.0,"perAdditionalEIPPerHour":0.005,"perNonAttachedPerHour":0.005,"perRemapFirst100":0.0,"perRemapOver100":0.1},"ec2_elb":{"perELBHour":0.034,"perGBProcessed":0.011},"rds":{"on_demand":{"mysql":{"standard":{"db.t2.micro":0.035,"db.t2.small":0.07,"db.t2.medium":0.14,"db.t2.large":0.282,"db.m3.medium":0.115,"db.m3.large":0.235,"db.m3.xlarge":0.47,"db.m3.2xlarge":0.94,"db.r3.4xlarge":3.977,"db.r3.8xlarge":7.954,"db.t1.micro":0.035,"db.m1.small":0.07,"db.m1.medium":0.145,"db.m1.large":0.29,"db.m1.xlarge":0.58,"db.m2.xlarge":0.405,"db.m2.2xlarge":0.815,"db.m2.4xlarge":1.63},"multi_az":{"db.t2.large":0.564,"db.m3.medium":0.23,"db.m3.large":0.47,"db.m3.xlarge":0.94,"db.m3.2xlarge":1.88,"db.r3.4xlarge":7.954,"db.r3.8xlarge":15.908,"db.t1.micro":0.07,"db.m1.small":0.14,"db.m1.medium":0.29,"db.m1.large":0.58,"db.m1.xlarge":1.16,"db.m2.xlarge":0.81,"db.m2.2xlarge":1.63,"db.m2.4xlarge":3.26}},"postgres":{"standard":{"db.t2.micro":0.038,"db.t2.small":0.076,"db.t2.medium":0.151,"db.t2.large":0.302,"db.m3.medium":0.12,"db.m3.large":0.245,"db.m3.xlarge":0.49,"db.m3.2xlarge":0.98,"db.r3.4xlarge":4.188,"db.r3.8xlarge":8.375,"db.t1.micro":0.035,"db.m1.small":0.075,"db.m1.medium":0.15,"db.m1.large":0.3,"db.m1.xlarge":0.605,"db.m2.xlarge":0.425,"db.m2.2xlarge":0.845,"db.m2.4xlarge":1.7},"multi_az":{"db.t2.large":0.604,"db.m3.medium":0.24,"db.m3.large":0.49,"db.m3.xlarge":0.98,"db.m3.2xlarge":1.96,"db.r3.4xlarge":8.375,"db.r3.8xlarge":16.75,"db.t1.micro":0.07,"db.m1.small":0.15,"db.m1.medium":0.3,"db.m1.large":0.6,"db.m1.xlarge":1.21,"db.m2.xlarge":0.85,"db.m2.2xlarge":1.69,"db.m2.4xlarge":3.4}},"oracle":{"standard":{"db.t2.micro":{"se1":0.05,"byol_or_nolicense":0.035},"db.t2.small":{"se1":0.1,"byol_or_nolicense":0.07},"db.t2.medium":{"se1":0.2,"byol_or_nolicense":0.14},"db.t2.large":{"se1":0.438,"byol_or_nolicense":0.282},"db.m3.medium":{"se1":0.235,"byol_or_nolicense":0.115},"db.m3.large":{"se1":0.47,"byol_or_nolicense":0.235},"db.m3.xlarge":{"se1":0.94,"byol_or_nolicense":0.47},"db.m3.2xlarge":{"se1":1.88,"byol_or_nolicense":0.94},"db.r3.4xlarge":{"se1":5.896,"byol_or_nolicense":3.977},"db.t1.micro":{"se1":0.05,"byol_or_nolicense":0.035},"db.m1.small":{"se1":0.135,"byol_or_nolicense":0.07},"db.m1.medium":{"se1":0.27,"byol_or_nolicense":0.145},"db.m1.large":{"se1":0.54,"byol_or_nolicense":0.29},"db.m1.xlarge":{"se1":1.08,"byol_or_nolicense":0.58},"db.m2.xlarge":{"se1":0.575,"byol_or_nolicense":0.405},"db.m2.2xlarge":{"se1":1.15,"byol_or_nolicense":0.815},"db.m2.4xlarge":{"se1":2.3,"byol_or_nolicense":1.63},"db.r3.8xlarge":{"byol_or_nolicense":7.954}},"multi_az":{"db.t2.large":{"se1":0.876,"byol_or_nolicense":0.564},"db.m3.medium":{"se1":0.47,"byol_or_nolicense":0.23},"db.m3.large":{"se1":0.94,"byol_or_nolicense":0.47},"db.m3.xlarge":{"se1":1.88,"byol_or_nolicense":0.94},"db.m3.2xlarge":{"se1":3.76,"byol_or_nolicense":1.88},"db.r3.4xlarge":{"se1":11.792,"byol_or_nolicense":7.954},"db.t1.micro":{"se1":0.1,"byol_or_nolicense":0.07},"db.m1.small":{"se1":0.27,"byol_or_nolicense":0.14},"db.m1.medium":{"se1":0.54,"byol_or_nolicense":0.29},"db.m1.large":{"se1":1.08,"byol_or_nolicense":0.58},"db.m1.xlarge":{"se1":2.16,"byol_or_nolicense":1.16},"db.m2.xlarge":{"se1":1.15,"byol_or_nolicense":0.81},"db.m2.2xlarge":{"se1":2.3,"byol_or_nolicense":1.63},"db.m2.4xlarge":{"se1":4.6,"byol_or_nolicense":3.26},"db.r3.8xlarge":{"byol_or_nolicense":15.908}}}}}}}')
#   end
# 
#   describe '.get_total_service_cost' do
#   	it "should return total cost" do
#   		service = @environment.services.first
#   		service.hourly_cost = 0.02
#   		# service.last_cost_update_time = Time.now - 2.hour
#   		# expect(CostData.get_total_service_cost(service).round(3)).to eq 0.04
#   	end
# 
#   	it "should return 0.0 if hourly cost is nil" do
#   		service = @environment.services.first
#   		# service.last_cost_update_time = Time.now - 2.hour
#   		# expect(CostData.get_total_service_cost(service).round(3)).to eq 0.0
#   	end
#   end
# 
#   describe ".update_cost_data" do
# 
#     it "should update cost data" do
#       allow(@account).to receive(:regions) {[@sao_paulo_region]}
#       allow(TemplateCostService).to receive(:search) { @template_data }
#       @service.last_cost_update_time = Time.now - 2.hour
#       @service.hourly_cost = 0.02
#       # cost_data = CostData.update_cost_data(@service.id)
#       # expect(cost_data).to be true
#     end
# 
#     it "should return nil if service is not chargeable" do
#       @service = FactoryBot.create(:service, :subnet_aws, :running, account: @account, region: @sao_paulo_region, adapter: @dev_adapter, environment: @environment)
#       # cost_data = CostData.update_cost_data(@service.id)
#       # expect(cost_data).to be nil
#     end
# 
#   end
# 
#   describe ".update_daily_data" do
#     it "should update cost data for all services" do
#       # cost_data = CostData.update_daily_data
#       # expect(cost_data).to be_an Array
#     end
#   end
# end
