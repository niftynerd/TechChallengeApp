# Tech Challenge App

## Overview

My solution to the Tech Challenge app. I haven't yet finished getting the database set up properly

### TODO

* Provision the database first and output parameter for endpoint
* Use endpoint parameter for db host in conf.toml file
* continue with deploy.sh script

### What it does right now

* Builds the docker image and pushes it to ecr
* Create s3 bucket for cfn files which are stored there for referencing as nested stacks
* Deploy cloudformation template which runs through all the files posted to s3

### How to use it

1. Deploys to AWS
2. In the deploy.sh script at the top where it says 'set env variables (to change)' set these for your region, aws_account_id and s3_bucket_name which you wish to create to your account
3. Run deploy.sh