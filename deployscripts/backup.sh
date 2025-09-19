#!/bin/bash
api_id=$(sudo docker ps | grep api-saas | awk '{print$1}')
api_master_id=$(sudo docker ps | grep api-master-saas | awk '{print$1}')
api_sidekiq_id=$(sudo docker ps | grep api-sidekiq-saas | awk '{print$1}')
api_cloudtrail_id=$(sudo docker ps | grep cloudtrail-sidekiq | awk '{print$1}')

script_path=/home/cloudstreet/api/deployscripts/utils

[[ ! -z "$api_id" ]] && docker exec -i $api_id /bin/bash $script_path/stop_services.sh
[[ ! -z "$api_master_id" ]] && docker exec -i $api_master_id /bin/bash $script_path/stop_services.sh
# [[ ! -z "$api_sidekiq_id" ]] && docker exec -i $api_sidekiq_id /bin/bash $script_path/stop_sidekiq_gracefully.sh
# [[ ! -z "$api_cloudtrail_id" ]] && docker exec -i $api_cloudtrail_id /bin/bash $script_path/stop_sidekiq_gracefully.sh

echo check