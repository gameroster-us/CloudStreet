#! /bin/bash

comment() {
  sed -i '' -e "$1"' s/^/  #/' "$2"
}

uncomment() {
  sed -i '' -e "$1"' s/^  #/ /' "$2"
}

sys_arch=$(uname -m)

# comment 9 app/controllers/application_controller.rb
uncomment 7,8 app/controllers/application_controller.rb
uncomment 12,18 app/controllers/application_controller.rb
uncomment 24,31 app/controllers/application_controller.rb

sed -i '' -e 19,28' s/^#//'  config/initializers/cors.rb

sed -i '' -e 9,19' s/^/#/' config/puma.rb

grep -qxF 'port 9506' config/puma.rb || echo 'port 9506' >> config/puma.rb

if [ "$sys_arch" == "arm64" ]
then
  comment 49 config/environments/development.rb
  sed -i '' -e "s/gem 'wkhtmltopdf-installer'/gem 'wkhtmltopdf-installer-arm64'\, git\: 'https\:\/\/github.com\/CSas\/wkhtmltopdf-installer-arm64'\, branch\: 'main'/g" Gemfile
  sed -i '' -e "s/gem 'wkhtmltopdf-binary'/gem 'wkhtmltopdf-binary'\, '0.12.6.5'/g" Gemfile

  sed -i '' -e "s/FROM CSmp\/api:base-6.0/FROM CSmp\/api:base-6.0-arm64-v1.0/g" Dockerfile
fi

sed -i '' -e 12'  s/\#{subdomain}.//' app/services/rest_client_service.rb

if ! grep -qx ":process_limits:" config/sidekiq.yml
then
tee -a config/sidekiq.yml <<-EOF
  - [api, 10]
  - [azure_idle_queue,10]
  - [azure_sync, 5]
  - [athena_group_sync, 5]
  - [azure_recommendation, 5]
  - [background_azure_idle_queue, 5]
  - [background_azure_sync, 5]
  - [background_gcp_idle_queue, 5]
  - [background_gcp_sync, 5]
  - [budget_queue, 5]
  - [cloud_trail, 20]
  - [gcp_idle_queue, 10]
  - [gcp_sync,  20]
  - [idle_service_queue, 30]
  - [metric, 5]
  - [service_adviser_summary, 5]
  - [rightsizing, 30]
  - [rightsizing_azure, 5]
  - [s3_rightsizing, 10]
  - [security_scan_data, 10]
  - [task_queue, 10]
:process_limits:
   sync: 5
   api: 5
   cloud_trail: 5
   task_queue: 5
EOF
fi


