#!/bin/sh

echo 'Launching the EKS stack...'
aws cloudformation create-stack \
  --capabilities CAPABILITY_IAM \
  --stack-name CapstoneEKS-Workers-Build-0 \
  --parameters file://parameters.json \
  --template-body file://eks-nodegroup-bg.yaml \
  --region us-east-2

