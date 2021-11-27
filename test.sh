#!/bin/bash

sudo docker run \
	--rm -it \
	--env SERVER_IDS=80,92 \
	-p 9469:9469 \
	-v $(pwd)/librespeed-backends.json:/librespeed-backends.json \
	--name test-librespeed \
	brendonmatheson/prometheus-librespeed-exporter:latest-local

