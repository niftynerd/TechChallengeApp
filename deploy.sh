#!/bin/bash

# set env variables (to change)
region=ap-southeast-2
aws_account_id=821329188402
s3_bucket_name=servian-geoff1337

# other variables
DbUser=postgres
DbPassword=changeme
DbName=mydb

# create s3 bucket for cloudformation templates
aws s3api create-bucket --bucket $s3_bucket_name --region ${region} --create-bucket-configuration LocationConstraint=${region}

# copy cfn files to s3
aws s3 cp cfn s3://${s3_bucket_name}/ --recursive

# deploy cfn stack
aws cloudformation deploy --template-file cfn/all.yaml --stack-name servian-stack --parameter-overrides S3BucketName=${s3_bucket_name} Region=${region} DbUser=${DbUser} DbPassword=${DbPassword} DBName=${DbName} --capabilities CAPABILITY_NAMED_IAM

# get rds endpoint url and append to conf file
endpoint_url=`aws cloudformation describe-stacks --query Stacks[].Outputs[?OutputKey==\'RDS\'].OutputValue --output text`
echo "\"DbHost\" = \"${endpoint_url}\"" >> conf.toml

# build docker image
imageName=servian/techchallengeapp
docker build . -t ${imageName}:latest

# revert conf file back to without rds endpoint
sed -i '$ d' conf.toml

# add data to db
docker run ${imageName} updatedb -s

# create ecr repo for docker image
aws ecr create-repository --repository-name $imageName

# push docker image to ecr repo
aws ecr get-login-password --region $region | docker login --username AWS --password-stdin ${aws_account_id}.dkr.ecr.${region}.amazonaws.com

image=${aws_account_id}.dkr.ecr.${region}.amazonaws.com/${imageName}:latest
docker tag ${imageName}:latest ${image}
docker push ${image}

# create service from pushed docker image
ContainerPort=3000
VPC=`aws cloudformation describe-stacks --query Stacks[].Outputs[?OutputKey==\'VPC\'].OutputValue --output text`
Cluster=`aws cloudformation describe-stacks --query Stacks[].Outputs[?OutputKey==\'Cluster\'].OutputValue --output text`
Listener=`aws cloudformation describe-stacks --query Stacks[].Outputs[?OutputKey==\'Listener\'].OutputValue --output text`
ECSServiceAutoScalingRoleARN=`aws cloudformation describe-stacks --query Stacks[].Outputs[?OutputKey==\'ECSServiceAutoScalingRole\'].OutputValue --output text`
DesiredCount=2

aws cloudformation deploy --template-file cfn/service.yaml --stack-name service-stack --parameter-overrides VPC=${VPC} Cluster=${Cluster} DesiredCount=${DesiredCount} Listener=${Listener} ECSServiceAutoScalingRoleARN=${ECSServiceAutoScalingRoleARN} Image=${image} ContainerPort=${ContainerPort} --capabilities CAPABILITY_NAMED_IAM
