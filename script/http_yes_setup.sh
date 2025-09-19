#!/bin/bash
. /data/mount/env
FILE_PATH=( "/data/mount/env" "/data/mount/env-report" "/etc/environment" "$APP_ROOT/script/reboot.sh" "$APP_ROOT/script/restart.sh" )
Permanent_NO_PROXY=127.0.0.1,localhost,127.0.0.1:9506,api,api:81,api:3200,report:82,web:443,169.254.169.254
sudo service nginx start
sleep 1
echo "nginx started"


for (( i=0; i<6; i++ ))
do
if [ "$#" -eq 3 ]; then
  if grep -Rq "http_proxy" ${FILE_PATH[$i]}
  then
    echo "Value present, setting new values "
  sudo sed -i -e 's/export http_proxy.*/export http_proxy=http:\/\/'$1':'$2'/g' ${FILE_PATH[$i]}
  sudo sed -i -e 's/export https_proxy.*/export https_proxy=https:\/\/'$1':'$2'/g' ${FILE_PATH[$i]}  
  else
       echo "Value not present, http proxy set ${FILE_PATH[$i]}"
        sudo sed -i -e '3iexport http_proxy=http://'$1':'$2'\' ${FILE_PATH[$i]}
        sudo sed -i -e '3iexport https_proxy=https://'$1':'$2'\' ${FILE_PATH[$i]}
 fi
else
  if grep -Rq "http_proxy" ${FILE_PATH[$i]}
  then
    echo "Value present, setting new values "
  sudo sed -i -e 's/export http_proxy.*/export http_proxy=http:\/\/'$3''$4''$1':'$2'/g' ${FILE_PATH[$i]}
  sudo sed -i -e 's/export https_proxy.*/export https_proxy=https:\/\/'$3''$4''$1':'$2'/g' ${FILE_PATH[$i]}
 else
       echo "Value not present, http proxy set ${FILE_PATH[$i]}"
        sudo sed -i -e '3iexport http_proxy=http://'$3''$4''$1':'$2'\' ${FILE_PATH[$i]}
        sudo sed -i -e '3iexport https_proxy=https://'$3''$4''$1':'$2'\' ${FILE_PATH[$i]}
  fi
fi

if [ "$#" -eq 5 ]; then
if [ -z "$5" ]; then
         sudo sed -i '/no_proxy/d' ${FILE_PATH[$i]}
         sudo bash -c  "echo 'export no_proxy=$Permanent_NO_PROXY' >> ${FILE_PATH[$i]}"
else
         sudo sed -i '/no_proxy/d' ${FILE_PATH[$i]}
         sudo bash -c  "echo 'export no_proxy=$5,$Permanent_NO_PROXY' >> ${FILE_PATH[$i]}"
fi
else
if [ -z "$3" ]; then
	sudo sed -i '/no_proxy/d' ${FILE_PATH[$i]}
        sudo bash -c  "echo 'export no_proxy=$Permanent_NO_PROXY' >> ${FILE_PATH[$i]}"
else
         sudo sed -i '/no_proxy/d' ${FILE_PATH[$i]}
         sudo bash -c  "echo 'export no_proxy=$3,$Permanent_NO_PROXY' >> ${FILE_PATH[$i]}"
fi
fi
done


for (( i=0; i<2; i++ ))
do
if [ "$#" -eq 3 ]; then
if grep -Rq "http-proxy" ${FILE_PATH[$i]}
	then
echo "Value present, setting new NPM values "
echo ${FILE_PATH[$i]}
sudo sed -i -e 's/.*npm set http-proxy.*/npm set http-proxy http:\/\/'$1':'$2'/g' ${FILE_PATH[$i]}
sudo sed -i -e 's/.*npm set https-proxy.*/npm set https-proxy http:\/\/'$1':'$2'/g' ${FILE_PATH[$i]}
else
 echo "NPM Set ${FILE_PATH[$i]}"
 echo ${FILE_PATH[$i]}
sudo sed -i -e '5inpm set http-proxy http://'$1':'$2'\' ${FILE_PATH[$i]}
sudo sed -i -e '5inpm set https-proxy http://'$1':'$2'\' ${FILE_PATH[$i]}
fi
else
if grep -Rq "http-proxy" ${FILE_PATH[$i]}
   then

sudo sed -i -e 's/.*npm set http-proxy.*/npm set http-proxy http:\/\/'$3''$4''$1':'$2'/g' ${FILE_PATH[$i]}
sudo sed -i -e 's/.*npm set https-proxy.*/npm set https-proxy http:\/\/'$3''$4''$1':'$2'/g' ${FILE_PATH[$i]}

else

	echo "NPM Set ${FILE_PATH[$i]}"
echo ${FILE_PATH[$i]}
sudo sed -i -e '5inpm set http-proxy http://'$3''$4''$1':'$2'\' ${FILE_PATH[$i]}
sudo sed -i -e '5inpm set https-proxy http://'$3''$4''$1':'$2'\' ${FILE_PATH[$i]}
fi
fi
done
source /data/mount/env
