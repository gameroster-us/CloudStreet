#!/bin/sh

set -e

# robocup
ruby /myapp/github-actions/rubocop_runner.rb
# while true; do echo hello world; sleep 1; done