#!/bin/bash

IFS=',' read -ra SERVER_ID_ARRAY <<< "$SERVER_IDS"

for SERVER_ID in "${SERVER_ID_ARRAY[@]}"
do

	# Get the result
	json=$(librespeed-cli --local-json librespeed-backends.json --server $SERVER_ID --json)
	
	# Parse out the values
	server=$(echo $json | jq ".server.name")
	bytes_sent=$(echo $json | jq ".bytes_sent")
	bytes_received=$(echo $json | jq ".bytes_received")
	ping=$(echo $json | jq ".ping")
	jitter=$(echo $json | jq ".jitter")
	upload=$(echo $json | jq ".upload")
	download=$(echo $json | jq ".download")
	
	# Produce the export line
	echo "librespeed_result{server=$server,bytes_sent=\"$bytes_sent\",bytes_received=\"$bytes_received\",ping=\"$ping\",jitter=\"$jitter\",upload=\"$upload\",download=\"$download\"} 1"
	
done

