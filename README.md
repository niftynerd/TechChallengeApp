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