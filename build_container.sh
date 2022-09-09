#!/bin/bash
CONTAINER_NAME=jiahuac/cs1260
docker build -t $CONTAINER_NAME:latest .
docker push $CONTAINER_NAME:latest