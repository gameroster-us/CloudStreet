#!/bin/bash
repo_name="api"
branch=$(git branch | sed -n -e 's/^\* \(.*\)/\1/p')
zipname=api-$(date +"%d-%m-%Y_%H:%M:%S")
sudo git archive -v --format=zip --output=$zipname.zip $branch


deploy() {
    deploy_appname=$1
    deploy_groupname=$2
    region_code=$3
    s3_bucket=$4

    aws s3 cp --region $region_code $zipname.zip s3://$s3_bucket/deploy/
    sleep 5
    aws deploy create-deployment \
    --region $region_code \
    --application-name $deploy_appname \
    --deployment-config-name CodeDeployDefault.OneAtATime \
    --file-exists-behavior OVERWRITE \
    --deployment-group-name $deploy_groupname \
    --description "my_deployment_with_script" \
    --s3-location bucket=$s3_bucket,bundleType=zip,key=deploy/$zipname.zip
}

PS3='Please select your environment: '
options=("DEV" "STAGE" "PROD" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "DEV")
            deploy CodeDeployDEVAPI us-east-2 cloudstreet-dev-ohio
            break
            ;;
        "STAGE")
            deploy CodeDeploySTAGEAPIMT CodeDeploySTAGEAPIMT us-west-2 cloudstreet-staging
            deploy CodeDeploySTAGEAPIMT CodeDeploySTAGEAPIMT1 us-west-2 cloudstreet-staging
            break
            ;;
        "PROD")
            deploy CodeDeployPRODAPI CodeDeployPRODAPI us-west-2 cloudstreet-deploy
            deploy CodeDeployPRODAPI CodeDeployPRODAPI-1 us-west-2 cloudstreet-deploy
            break
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done


sudo rm $zipname.zip