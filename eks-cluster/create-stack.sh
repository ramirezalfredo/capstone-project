#!/bin/sh

S3BUCKET=s3://alfredos-eks-templates
echo 'Copying the CloudFormation templates to the S3 bucket...'
aws s3 cp eks-vpc.yaml $S3BUCKET
aws s3 cp eks-cluster.yaml $S3BUCKET
aws s3 cp eks-nodegroup.yaml $S3BUCKET

echo 'Launching the EKS stack...'
aws cloudformation create-stack \
--capabilities CAPABILITY_IAM \
--stack-name CapstoneEKS \
--parameters file://parameters.json \
--template-body file://eks-master.yaml \
--region us-east-2
