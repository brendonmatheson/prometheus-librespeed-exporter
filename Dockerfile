ARG TARGET_ARCH=
FROM ${TARGET_ARCH}alpine:3.15.0

# The version of the librespeed/speedtest-cli to use in this build
ENV CLI_VERSION=1.0.9

# The version of the script_exporter to use in this build
ENV SCRIPT_EXPORTER_VERSION=2.5.0

RUN apk add jq tar curl ca-certificates bash

# Download and install the librespeed-cli command-line tool
RUN export ARCH=$(apk info --print-arch) && \
	echo ARCH=${ARCH} && \
	case "$ARCH" in \
		x86) _arch=386 ;; \
		x86_64) _arch=amd64 ;; \
		*) _arch=$ARCH ;; \
	esac && \
	echo _arch=$_arch && \
        URL=https://github.com/librespeed/speedtest-cli/releases/download/v${CLI_VERSION}/librespeed-cli_${CLI_VERSION}_linux_${_arch}.tar.gz && \
	echo Pulling CLI from $URL && \
	curl -fsSL -o /tmp/cli.tgz $URL && \
	tar xvzf /tmp/cli.tgz -C /usr/local/bin librespeed-cli && \
	rm /tmp/cli.tgz

# Download and install the script_exporter binary
RUN export ARCH=$(apk info --print-arch) && \
	echo ARCH=${ARCH} && \
	case "$ARCH" in \
		x86) _arch=386 ;; \
		x86_64) _arch=amd64 ;; \
		armhf) _arch=armv7 ;; \
		*) _arch=$ARCH ;; \
	esac && \
	echo _arch=$_arch && \
        URL=https://github.com/ricoberger/script_exporter/releases/download/v${SCRIPT_EXPORTER_VERSION}/script_exporter-linux-${_arch} && \
	echo Pulling script_exporter from $URL && \
	curl -kfsSL -o /usr/local/bin/script_exporter $URL && \
	chmod 700 /usr/local/bin/script_exporter

COPY config.yaml config.yaml
COPY librespeed-exporter.sh /usr/local/bin/librespeed-exporter.sh

EXPOSE 9469

ENTRYPOINT [ "/usr/local/bin/script_exporter" ]

