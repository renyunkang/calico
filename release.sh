#!/bin/bash

REPO=${REPO:-rykren}
TAG=${TAG:-v3.23}
IMAGE=${IMAGE:-cni}
PUSH=${PUSH:-false}
arch=(amd64 arm64 armv7 ppc64le s390x) # 

docker builder prune
# cd ./calico
rm -r ./cni-plugin/bin


# build docker IMAGE
for i in "${arch[@]}"
do
   make -C cni-plugin image DEV_REGISTRIES=$REPO ARCH=$i
   if [ "$TAG" != "latest" ]; then
      make retag-build-images-with-registries DEV_REGISTRIES=$REPO BUILD_IMAGES=$IMAGE VALIDARCHES=$i IMAGETAG=$TAG
   fi
done

# push image manifest
if [ "$PUSH" = true ]; then
   manifest=""
   for i in "${arch[@]}"
   do
      # make cd-common DEV_REGISTRIES=$REPO BUILD_IMAGES=$IMAGE BRANCH_NAME=$TAG IMAGETAG=$TAG VALIDARCHES=$i CONFIRM=1
      # make push-images-to-registries DEV_REGISTRIES=$REPO BUILD_IMAGES=$IMAGE IMAGETAG=$TAG VALIDARCHES=$i CONFIRM=1
      # make push-manifests DEV_REGISTRIES=$REPO BUILD_IMAGES=$IMAGE IMAGETAG=$TAG VALIDARCHES=$i CONFIRM=1
      docker push $REPO/$IMAGE:$TAG-$i
      manifest+=$REPO/$IMAGE:$TAG-$i
      manifest+=" "
   done

   echo $manifest
   docker manifest rm $REPO/$IMAGE:$TAG
   docker manifest create $REPO/$IMAGE:$TAG $manifest --amend
   docker manifest push $REPO/$IMAGE:$TAG
fi

