#!/bin/bash

echo "# SERVER_IDS $SERVER_IDS"

if [ -z "$SERVER_IDS" ]
then
	echo "# No server's specified"

	# Get the result
	JSON=$(librespeed-cli --local-json librespeed-backends.json --json)

	# Parse out the values
	SERVER=$(echo $JSON | jq ".server.name")
	BYTES_SENT=$(echo $JSON | jq ".bytes_sent")
	BYTES_RECEIVED=$(echo $JSON | jq ".bytes_received")
	PING=$(echo $JSON | jq ".ping")
	JITTER=$(echo $JSON | jq ".jitter")
	UPLOAD=$(echo $JSON | jq ".upload")
	DOWNLOAD=$(echo $JSON | jq ".download")

        echo "# SERVER $SERVER"

	# Produce the export line
	echo librespeed_bytes_sent{server=$SERVER} $BYTES_SENT
	echo librespeed_bytes_received{server=$SERVER} $BYTES_RECEIVED
	echo librespeed_ping{server=$SERVER} $PING
	echo librespeed_jitter{server=$SERVER} $JITTER
	echo librespeed_upload{server=$SERVER} $UPLOAD
	echo librespeed_download{server=$SERVER} $DOWNLOAD
else
	IFS=',' read -ra SERVER_ID_ARRAY <<< "$SERVER_IDS"

	for SERVER_ID in "${SERVER_ID_ARRAY[@]}"
	do
	        echo "# SERVER_ID $SERVER_ID"

		# Get the result
		JSON=$(librespeed-cli --local-json librespeed-backends.json --server $SERVER_ID --json)

		# Parse out the values
		SERVER=$(echo $JSON | jq ".server.name")
		BYTES_SENT=$(echo $JSON | jq ".bytes_sent")
		BYTES_RECEIVED=$(echo $JSON | jq ".bytes_received")
		PING=$(echo $JSON | jq ".ping")
		JITTER=$(echo $JSON | jq ".jitter")
		UPLOAD=$(echo $JSON | jq ".upload")
		DOWNLOAD=$(echo $JSON | jq ".download")

	        echo "# SERVER $SERVER"

		# Produce the export line
		echo librespeed_bytes_sent{server=$SERVER} $BYTES_SENT
		echo librespeed_bytes_received{server=$SERVER} $BYTES_RECEIVED
		echo librespeed_ping{server=$SERVER} $PING
		echo librespeed_jitter{server=$SERVER} $JITTER
		echo librespeed_upload{server=$SERVER} $UPLOAD
		echo librespeed_download{server=$SERVER} $DOWNLOAD
	done
fi

