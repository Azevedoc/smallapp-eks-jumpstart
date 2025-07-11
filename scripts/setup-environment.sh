#!/bin/bash
# Environment setup script
export AWS_REGION="us-east-1"
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
export VOTING_APP_PATH="/c/Users/Azevedo/repos/Personal-GitHub/example-voting-app"
export CLUSTER_NAME="happy-dance-badger"

echo "Environment variables set:"
echo "AWS_REGION: $AWS_REGION"
echo "AWS_ACCOUNT_ID: $AWS_ACCOUNT_ID"
echo "ECR_REGISTRY: $ECR_REGISTRY"
echo "VOTING_APP_PATH: $VOTING_APP_PATH"
echo "CLUSTER_NAME: $CLUSTER_NAME (Auto Mode enabled)"