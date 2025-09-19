# !/bin/bash

imageName="api-base-ruby-2.5.9"
docker build -t $imageName . -f Dockerfile.base