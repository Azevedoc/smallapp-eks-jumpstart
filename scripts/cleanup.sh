#!/bin/bash
# Cleanup resources
source scripts/setup-environment.sh

echo "Cleaning up Kubernetes resources..."
kubectl delete namespace voting-app

echo "Cleaning up ECR repositories..."
aws ecr delete-repository --repository-name vote --force --region $AWS_REGION
aws ecr delete-repository --repository-name result --force --region $AWS_REGION
aws ecr delete-repository --repository-name worker --force --region $AWS_REGION

echo "Cleaning up EKS cluster..."
echo "Note: Delete the EKS cluster '$CLUSTER_NAME' from AWS Console"
echo "Or use AWS CLI:"
echo "aws eks delete-cluster --name $CLUSTER_NAME --region $AWS_REGION"

echo "Cleanup complete!"