#!/bin/bash

# set env variables (to change)
region=ap-southeast-2
aws_account_id=821329188402
s3_bucket_name=servian-geoff1337

# other variables
DbUser=postgres
DbPassword=changeme
ContainerPort=3000

# build docker image
imageName=servian/techchallengeapp
docker build . -t ${imageName}:latest

# create ecr repo for docker image
aws ecr create-repository --repository-name $imageName

# push docker image to ecr repo
aws ecr get-login-password --region $region | docker login --username AWS --password-stdin ${aws_account_id}.dkr.ecr.${region}.amazonaws.com

image=${aws_account_id}.dkr.ecr.${region}.amazonaws.com/${imageName}:latest
docker tag ${imageName}:latest ${image}
docker push ${image}

# create s3 bucket for cloudformation templates
aws s3api create-bucket --bucket $s3_bucket_name --region ${region} --create-bucket-configuration LocationConstraint=${region}

# copy cfn files to s3
aws s3 cp cfn s3://${s3_bucket_name}/ --recursive

# deploy cfn stack
aws cloudformation deploy --template-file cfn/all.yaml --stack-name servian-stack --parameter-overrides S3BucketName=${s3_bucket_name} Region=${region} DbUser=${DbUser} DbPassword=${DbPassword} Image=${image} ContainerPort=${ContainerPort} --capabilities CAPABILITY_NAMED_IAM
