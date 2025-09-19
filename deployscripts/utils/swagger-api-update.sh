#!/bin/bash
source /data/mount/env
sed -i "s/env-domain/$WEB_HOST/g" /home/cloudstreet/api/public/swagger-docs/main/index.html
sed -i "s/env-domain/$WEB_HOST/g" /home/cloudstreet/api/swagger/v2/swagger.yaml
sudo service nginx restart
