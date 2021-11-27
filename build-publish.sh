#!/bin/bash

VERSION=$1

sudo docker buildx build --platform linux/arm/v7,linux/amd64 --output=type=registry --tag brendonmatheson/prometheus-librespeed-exporter:$VERSION .

