#!/bin/bash

# Get the current AWS region from the instance metadata
region=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

# Define a variable holding the base AWS Secrets Manager command without the eval
get_secret_base="aws secretsmanager get-secret-value --query SecretString --region $region --output text"

#API ENV
CENTRAL_API_AUTH_TOKEN=$($get_secret_base --secret-id CENTRAL_API_AUTH_TOKEN | sed 's|"||g')
GCP_API_KEY=$($get_secret_base --secret-id GCP_API_KEY | sed 's|"||g')
CUSTOMERIO_API_CLIENT_KEY=$($get_secret_base --secret-id CUSTOMERIO_API_CLIENT_KEY | sed 's|"||g')
FLIPPER_USERNAME=$($get_secret_base --secret-id FLIPPER_USERNAME | sed 's|"||g')
FLIPPER_PASSWORD=$($get_secret_base --secret-id FLIPPER_PASSWORD | sed 's|"||g')

#Common ENV
CUSTOMERIO_SITE_ID=$($get_secret_base --secret-id CUSTOMERIO_SITE_ID | sed 's|"||g')
CUSTOMERIO_API_KEY=$($get_secret_base --secret-id CUSTOMERIO_API_KEY | sed 's|"||g')
SECRET_TOKEN=$($get_secret_base --secret-id SECRET_TOKEN | sed 's|"||g')
DEVISE_PEPPER=$($get_secret_base --secret-id DEVISE_PEPPER | sed 's|"||g')
BUNDLE_GEMS__CONTRIBSYS__COM=$($get_secret_base --secret-id BUNDLE_GEMS__CONTRIBSYS__COM | sed 's|"||g')
HONEYBADGER_API_KEY=$($get_secret_base --secret-id HONEYBADGER_API_KEY | sed 's|"||g')
SES_USERNAME=$($get_secret_base --secret-id SES_USERNAME | sed 's|"||g')
SES_PASSWORD=$($get_secret_base --secret-id SES_PASSWORD | sed 's|"||g')
AWS_ACCESS_KEY_ID=$($get_secret_base --secret-id AWS_ACCESS_KEY_ID | sed 's|"||g')
AWS_SECRET_ACCESS_KEY=$($get_secret_base --secret-id AWS_SECRET_ACCESS_KEY | sed 's|"||g')
STS_AWS_ACCESS_KEY_ID=$($get_secret_base --secret-id STS_AWS_ACCESS_KEY_ID | sed 's|"||g')
STS_SECRET_ACCESS_KEY=$($get_secret_base --secret-id STS_SECRET_ACCESS_KEY | sed 's|"||g')
DATABASE_NAME=$($get_secret_base --secret-id DATABASE_NAME | sed 's|"||g')
DATABASE_USER=$($get_secret_base --secret-id DATABASE_USER | sed 's|"||g')
DATABASE_PASSWORD=$($get_secret_base --secret-id DATABASE_PASSWORD | sed 's|"||g')
DATABASE_HOST=$($get_secret_base --secret-id DATABASE_HOST | sed 's|"||g')
SLACK_API_TOKEN=$($get_secret_base --secret-id SLACK_API_TOKEN | sed 's|"||g')
FIXER_ACCESS_KEY=$($get_secret_base --secret-id FIXER_ACCESS_KEY | sed 's|"||g')
SECRET_KEY_BASE=$($get_secret_base --secret-id SECRET_KEY_BASE | sed 's|"||g')

#API-SECRETS
export CENTRAL_API_AUTH_TOKEN="$CENTRAL_API_AUTH_TOKEN"
export GCP_API_KEY="$GCP_API_KEY"
export CUSTOMERIO_API_CLIENT_KEY="$CUSTOMERIO_API_CLIENT_KEY"
export FLIPPER_USERNAME="$FLIPPER_USERNAME"
export FLIPPER_PASSWORD="$FLIPPER_PASSWORD"

#COMMON-SECRETS
export CUSTOMERIO_SITE_ID="$CUSTOMERIO_SITE_ID"
export CUSTOMERIO_API_KEY="$CUSTOMERIO_API_KEY"
export SECRET_TOKEN="$SECRET_TOKEN"
export DEVISE_PEPPER="$DEVISE_PEPPER"
export BUNDLE_GEMS__CONTRIBSYS__COM="$BUNDLE_GEMS__CONTRIBSYS__COM"
export HONEYBADGER_API_KEY="$HONEYBADGER_API_KEY"
export SES_USERNAME="$SES_USERNAME"
export SES_PASSWORD="$SES_PASSWORD"
export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
export STS_AWS_ACCESS_KEY_ID="$STS_AWS_ACCESS_KEY_ID"
export STS_SECRET_ACCESS_KEY="$STS_SECRET_ACCESS_KEY"
export DATABASE_NAME="$DATABASE_NAME"
export DATABASE_USER="$DATABASE_USER"
export DATABASE_PASSWORD="$DATABASE_PASSWORD"
export DATABASE_HOST="$DATABASE_HOST"
export SLACK_API_TOKEN="$SLACK_API_TOKEN"
export FIXER_ACCESS_KEY="$FIXER_ACCESS_KEY"
export SECRET_KEY_BASE="$SECRET_KEY_BASE"
