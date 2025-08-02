#!/bin/bash
# dev-container.sh: Build and run the universal dev/test Docker container for Mrs. Violet Noire

IMAGE_NAME=violet-noire-dev
PORT=8080

# Build the Docker image

echo "Building Docker image..."
docker build -t $IMAGE_NAME . || { echo "Docker build failed"; exit 1; }

echo "Running container on http://localhost:$PORT ..."
docker run --rm -it -p $PORT:80 $IMAGE_NAME
