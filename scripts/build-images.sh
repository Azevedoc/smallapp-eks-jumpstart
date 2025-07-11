#!/bin/bash
# Build and push Docker images
source scripts/setup-environment.sh

echo "Building images..."
docker build -t vote:latest $VOTING_APP_PATH/vote
docker build -t result:latest $VOTING_APP_PATH/result
docker build -t worker:latest $VOTING_APP_PATH/worker

echo "Tagging images..."
docker tag vote:latest $ECR_REGISTRY/vote:latest
docker tag result:latest $ECR_REGISTRY/result:latest
docker tag worker:latest $ECR_REGISTRY/worker:latest

echo "Pushing images..."
docker push $ECR_REGISTRY/vote:latest
docker push $ECR_REGISTRY/result:latest
docker push $ECR_REGISTRY/worker:latest

echo "Images pushed successfully!"