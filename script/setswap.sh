#!/bin/bash
swap_value=$(free -m | grep -v grep | grep Swap | awk {'print $2'})
path="/"
swapfile="swapfile"
memory="4G"
if [ "$swap_value" == "0" ];
then
cd $path
sudo touch $swapfile 
sudo fallocate -l $memory $path$swapfile
sudo mkswap $path$swapfile
sudo swapon $path$swapfile
sudo echo "$path$swapfile   none    swap    sw    0   0" >> /etc/fstab
else
echo "swap already present"
fi