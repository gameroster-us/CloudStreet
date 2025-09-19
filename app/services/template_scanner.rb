class TemplateScanner <  CloudStreetService
  attr_accessor :template_data

  RESOURCE_TYPE_MAP = {
    "AWS::EC2::SecurityGroup" => "SecurityGroup",
    "AWS::EC2::SecurityGroupEgress" => "SecurityGroupEgress",
    "AWS::EC2::SecurityGroupIngress" => "SecurityGroupIngress",
    "AWS::EC2::Instance" => "EC2Instance",
    "AWS::S3::Bucket" => "S3Bucket",
    "AWS::EC2::Volume" => "Volume",
    "AWS::RDS::DBInstance" => "Rds",
    "AWS::ElasticLoadBalancing::LoadBalancer" => "LoadBalancer"
  }.freeze

  RESOURCE_IAM = {
    "AWS::IAM::User" => "IamUser",
    "AWS::IAM::Role" => "IamRole",
    "AWS::IAM::Policy" => "IamPolicy"
  }.freeze

  def initialize
    @template_data = []
  end

  class << self

    def template_scan(params, &block)
      type = params.try(:[], :type)
      contents = params.try(:[], :contents)
      resources = type.eql?('yaml') ? YAML.load(contents) : JSON.parse(contents)
      resources = resources.try(:[], 'Resources')
      template_data = get_resources(resources, &block)
      status Status, :success, { data: template_data }, &block
    end

    def get_resources(resources, &block)
      return if resources.blank?

      template_data = []
      iam_resources = resources.values.select { |iam_res| RESOURCE_IAM.include?(iam_res['Type']) }
      if iam_resources.present?
        scanner = "CloudFormation::TemplateScanners::Iam".constantize.new(template_data)
        template_data = scanner.start_template_scanning(iam_resources)
      end
      resources.values.each do |resource|
        next unless RESOURCE_TYPE_MAP.include?(resource['Type'])
        scanner = "CloudFormation::TemplateScanners::#{RESOURCE_TYPE_MAP[resource['Type']]}".constantize.new(template_data)
        template_data = scanner.start_template_scanning(resource['Properties'])
      end
      template_data
    end

  end

end
