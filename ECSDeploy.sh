#!/bin/bash

set -e

CURRENT_DIR=$PWD
DOCKER_DIR=$CURRENT_DIR/../XXXXXX
export AWS_PROFILE=ecsuserXXXXXX

ZKEEPER_REPO=$REGISTRY/XXXXXX-zookeeper:$DOCKER_IMAGE_VERSION
PGDATALOAD_REPO=$REGISTRY/XXXXXX-pgsql-loaddata:$DOCKER_IMAGE_VERSION
XXXXXX_INT_REPO=$REGISTRY/XXXXXX-integration-service:$DOCKER_IMAGE_VERSION
XXXXXX_CORE_REPO=$REGISTRY/XXXXXX-core-service:$DOCKER_IMAGE_VERSION
NGINX_REPO=$REGISTRY/XXXXXX-nginx:$DOCKER_IMAGE_VERSION


buildimages()
{

echo "-----------------------------"
echo "Docker Image Version --- $DOCKER_IMAGE_VERSION ---"
echo "-----------------------------"

echo "[INFO] --- Building Docker Image for XXXXXX-zookeeper ---"
docker image build -t $ZKEEPER_REPO $DOCKER_DIR/XXXXXX-zookeeper

echo "[INFO] --- Building Docker Image for XXXXXX-pgsql-loaddata ---"
docker image build -t $PGDATALOAD_REPO $DOCKER_DIR/XXXXXX-pgsql-loaddata

echo "[INFO] --- Building Docker Image for XXXXXX-integration-service ---"
docker image build -t $XXXXXX_INT_REPO $DOCKER_DIR/XXXXXX-integration-service

echo "[INFO] --- Building Docker Image for XXXXXX-core-service ---"
docker image build -t $XXXXXX_CORE_REPO $DOCKER_DIR/XXXXXX-core-service

echo "[INFO] --- Building Docker Image for XXXXXX-nginx ---"
docker image build -t $NGINX_REPO $DOCKER_DIR/XXXXXX-nginx

pushimages

}

pushimages()
{

echo 'y' | $(aws ecr get-login | sed -e 's/-e\ none/''/g') #login to AWS ECR
echo "[INFO] --- ECR LOGIN SUCCESS ---"

docker image push $ZKEEPER_REPO
echo "[INFO] --- Uploading Docker Image for XXXXXX-zookeeper ---"

docker image push $PGDATALOAD_REPO
echo "[INFO] --- Uploading Docker Image for XXXXXX-pgsql-loaddata ---"

docker image push $XXXXXX_INT_REPO
echo "[INFO] --- Uploading Docker Image for XXXXXX-integration-service ---"

docker image push $XXXXXX_CORE_REPO
echo "[INFO] --- Uploading Docker Image for XXXXXX-core-service ---"

docker image push $NGINX_REPO
echo "[INFO] --- Uploading Docker Image for XXXXXX-nginx ---"

registertask

}


registertask()
{

sed -i 's@IMGNAME_ZOOKEEPER@'"$ZKEEPER_REPO"'@g' $CURRENT_DIR/task-definitions/zookeeper.json
sed -i 's@IMGNAME_PGDATALOAD@'"$PGDATALOAD_REPO"'@g' $CURRENT_DIR/task-definitions/pgdataload.json
sed -i 's@IMGNAME_XXXXXXCORE@'"$XXXXXX_CORE_REPO"'@g' $CURRENT_DIR/task-definitions/XXXXXX.json
sed -i 's@IMGNAME_XXXXXXINTEGRATION@'"$XXXXXX_INT_REPO"'@g' $CURRENT_DIR/task-definitions/XXXXXX.json
sed -i 's@IMGNAME_NGINX@'"$NGINX_REPO"'@g' $CURRENT_DIR/task-definitions/nginx.json
echo "[INFO] --- Task definition's docker image name has been updated ---"


aws ecs register-task-definition --cli-input-json file://$CURRENT_DIR/task-definitions/zookeeper.json
aws ecs register-task-definition --cli-input-json file://$CURRENT_DIR/task-definitions/pgdataload.json
aws ecs register-task-definition --cli-input-json file://$CURRENT_DIR/task-definitions/XXXXXX.json
aws ecs register-task-definition --cli-input-json file://$CURRENT_DIR/task-definitions/nginx.json
echo "[INFO] --- All the task definitions has been registered ---"

removeimage_local

}

removeimage_local()
{

docker image rm -f $ZKEEPER_REPO

docker image rm -f $PGDATALOAD_REPO

docker image rm -f $XXXXXX_CORE_REPO

docker image rm -f $XXXXXX_INT_REPO

docker image rm -f $NGINX_REPO

echo "[INFO] --- Removed all the images from jenkins server ---"

removeservices

}

removeservices()
{
  aws ecs update-service --cluster XXXXXX-qa --service XXXXXX-zookeeper --task-definition XXXXXX-zookeeper --desired-count 0
  aws ecs update-service --cluster XXXXXX-qa --service XXXXXX-ms --task-definition XXXXXX-ms --desired-count 0
  aws ecs update-service --cluster XXXXXX-qa --service XXXXXX-nginx --task-definition XXXXXX-nginx --desired-count 0
  sleep 45s
  aws ecs delete-service --cluster XXXXXX-qa --service XXXXXX-zookeeper
  sleep 5s
  aws ecs delete-service --cluster XXXXXX-qa --service XXXXXX-ms
  sleep 5s
  aws ecs delete-service --cluster XXXXXX-qa --service XXXXXX-nginx
  sleep 45s

  runservices
}

runservices()
{

echo "[INFO] --- Running task XXXXXX-pgdataload ---"
aws ecs run-task --cluster XXXXXX-qa --task-definition XXXXXX-pgdataload --count 1

echo "[INFO] --- Running service XXXXXX-zookeeper ---"
aws ecs create-service --cluster XXXXXX-qa --service-name XXXXXX-zookeeper --task-definition XXXXXX-zookeeper --desired-count 1

echo "[INFO] --- Running service XXXXXX-ms ---"
aws ecs create-service --cluster XXXXXX-qa --service-name XXXXXX-ms --task-definition XXXXXX-ms --desired-count 1

echo "[INFO] --- Running service XXXXXX-nginx ---"
aws ecs create-service --cluster XXXXXX-qa --service-name XXXXXX-nginx --task-definition XXXXXX-nginx --desired-count 1

}

buildimages
