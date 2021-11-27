#!/bin/bash

BACKENDS_JSON_FILE=/librespeed-backends.json

if [ "$PERFORM_DOWNLOAD" == "FALSE" ]
then
	DOWNLOAD_SWITCH=--no-download
fi

if [ "$PERFORM_UPLOAD" == "FALSE" ]
then
	UPLOAD_SWITCH=--no-upload
fi

echo $DOWNLOAD_SWITCH
echo $UPLOAD_SWITCH

if [ -z "$SERVER_IDS" ]
then
	echo "# No server's specified"

	# Get the result
	if [ -f "$BACKENDS_JSON_FILE" ]
	then
		echo "# Using custom backends file"
		JSON=$(librespeed-cli $DOWNLOAD_SWITCH $UPLOAD_SWITCH --local-json $BACKENDS_JSON_FILE --json)
	else
		echo "# Not using custom backends file"
		JSON=$(librespeed-cli $DOWNLOAD_SWITCH $UPLOAD_SWITCH --json)
	fi

	echo "# JSON: $JSON"

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

	if [ "$PERFORM_DOWNLOAD" != "FALSE" ]
	then
		echo "# Emitting download metric"
		echo librespeed_download{server=$SERVER} $DOWNLOAD
	fi

	if [ "$PERFORM_UPLOAD" != "FALSE" ]
	then
		echo "# Emitting upload metric"
		echo librespeed_upload{server=$SERVER} $UPLOAD
	fi
else
	echo "# Server's specified: $SERVER_IDS"

	IFS='|' read -ra SERVER_ID_ARRAY <<< "$SERVER_IDS"

	for SERVER_ID in "${SERVER_ID_ARRAY[@]}"
	do
	        echo "# SERVER_ID $SERVER_ID"

		# Get the result
		if [ -f "$BACKENDS_JSON_FILE" ]
		then
			echo "# Using custom backends file"
			JSON=$(librespeed-cli $DOWNLOAD_SWITCH $UPLOAD_SWITCH --local-json $BACKENDS_JSON_FILE --server $SERVER_ID --json)
		else
			echo "# Not using custom backends file"
			JSON=$(librespeed-cli $DOWNLOAD_SWITCH $UPLOAD_SWITCH --json)
		fi

		echo "# JSON: $JSON"

		# Parse out the values
		SERVER=$(echo $JSON | jq ".server.name")
		BYTES_SENT=$(echo $JSON | jq ".bytes_sent")
		BYTES_RECEIVED=$(echo $JSON | jq ".bytes_received")
		PING=$(echo $JSON | jq ".ping")
		JITTER=$(echo $JSON | jq ".jitter")
		DOWNLOAD=$(echo $JSON | jq ".download")
		UPLOAD=$(echo $JSON | jq ".upload")

	        echo "# SERVER $SERVER"

		# Produce the export line
		echo librespeed_bytes_sent{server=$SERVER} $BYTES_SENT
		echo librespeed_bytes_received{server=$SERVER} $BYTES_RECEIVED
		echo librespeed_ping{server=$SERVER} $PING
		echo librespeed_jitter{server=$SERVER} $JITTER

		if [ "$PERFORM_DOWNLOAD" != "FALSE" ]
		then
			echo librespeed_download{server=$SERVER} $DOWNLOAD
		fi

		if [ "$PERFORM_UPLOAD" != "FALSE" ]
		then
			echo librespeed_upload{server=$SERVER} $UPLOAD
		fi
	done
fi

