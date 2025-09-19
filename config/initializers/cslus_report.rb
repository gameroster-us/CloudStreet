ATHENA_DATABASE="CSreports".freeze
ATHENA_METRIC_DATABASE="CS_metrics".freeze
ATHENA_WORKGROUP="CloudStreet-workgroup".freeze
RAW_REPORT_BUCKET=(ENV["RAW_REPORT_BUCKET"] || "raw-reports-test").freeze
PARQUET_REPORT_BUCKET=(ENV["PARQUET_REPORT_BUCKET"] || "parquet-reports-test").freeze
GLUE_JOB_NAME=(ENV["GLUE_JOB_NAME"] || "parquet-reports-test").freeze
AZURE_GLUE_JOB_NAME=(ENV["AZURE_GLUE_JOB_NAME"] || "csv-to-parquet-azure-test").freeze
APP_REGION=(ENV["APP_REGION"] || "us-west-2").freeze

RAW_METRIC_BUCKET=(ENV["RAW_METRIC_BUCKET"] || "raw-metrics-test").freeze
PARQUET_METRIC_BUCKET=(ENV["PARQUET_METRIC_BUCKET"] || "parquet-metrics-test").freeze

V2_API = true
ADAPTERS_LIMIT = 99
ADAPTERS_LIMIT_FOR_MAXAR = 300
BILLING_CONFIG_CACHE_EXPIRY = (ENV['BILLING_CONFIG_CACHE_EXPIRY'] || 5).to_f.hours.to_i
ACTIVE = 'active'.freeze
DELETED = 'deleted'.freeze
BUDGET_UPDATE_URL_MAPPER = { AWSBudget: "#{Settings.report_host}/api/v1/budgets", AzureBudget: "#{Settings.report_host}/api/v1/azure_budgets", GCPBudget: "#{Settings.report_host}/api/v1/gcp_budgets" }.with_indifferent_access
GROUP_CSV_TO_PARQUET_GLUE_JOB_NAME = 'adapter-groups-csv-to-parquet'.freeze
GLUE_JOB_STATUSES = %w[SUCCEEDED FAILED].freeze
GROUP_PROCESSING_BATCH_SIZE_FOR_CSV = 2000.freeze
CLOUDSTREET_NULL = 'CloudStreet-NULL'
CLOUDSTREET_KEY = 'CloudStreet-key'
GROUP_TYPE_MAP = {
'AWS' => 'account_group',
'Azure' => 'subscription_group',
'GCP' => 'project_group'
}.freeze
AZURE_EXCLUDE_SERVICE_NAME = [ 
	'Office 365 E1',
	'Office 365 E3',
	'Knowler365',
	'Microsoft 365 New Commerce Promotional Offer Annual',
	'Microsoft 365 Audio Conferencing Adoption Promo',
	'Microsoft 365 New Commerce Promotional Offer Monthly',
	'Microsoft Defender for Office 365 (Plan 1)',
	'Office 365 Extra File Storage'
].freeze

PROD_REGIONS = {
  'ca-central-1': 'PROD-CANADA',
  'us-west-2': 'PROD-OREGON',
  'ap-southeast-2': 'PROD-SYDNEY',
  'eu-central-1': 'PROD-FF',
  'ap-southeast-1': 'PROD-SINGAPORE',
  'eu-west-2': 'PROD-LONDON',
  'eu-west-1': 'PROD-IRELAND'
}.freeze

SLACK_API_TOKEN = ENV['SLACK_API_TOKEN']
SLACK_AWS_ALERT_CHANNEL = '#csmp-hb-alerts-slack-aws'
SLACK_AZURE_ALERT_CHANNEL = '#csmp-hb-alerts-slack-azure'
SLACK_GCP_ALERT_CHANNEL = '#csmp-hb-alerts-slack-gcp'
SLACK_VMWARE_ALERT_CHANNEL = '#csmp-hb-alerts-slack-vmware'
