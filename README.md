# prometheus-librespeed-exporter

## Introduction

This project packages the [speedtest-cli](https://github.com/librespeed/speedtest-cli) provided by the [librespeed](https://github.com/librespeed) project as a [Prometheus](https://prometheus.io/) exporter that can be used for measuring network performance.

This exporter is available as a [multi-arch image in Docker Hub](https://hub.docker.com/r/brendonmatheson/prometheus-librespeed-exporter) and the sources are offered through [GitHub](https://github.com/brendonmatheson/prometheus-librespeed-exporter) under the terms of the Apache Software License.

## Acknowledgement

The approach used in this project is styled after the work of [billimek](https://github.com/billimek) in his [prometheus-speedtest-exporter](https://github.com/billimek/prometheus-speedtest-exporter) that builds a [script_exporter](https://github.com/ricoberger/script_exporter) on the [Ookla speedtest-cli](https://www.speedtest.net/apps/cli)

## Quick Start

### Introduction

In this quick start we will launch the exporter with default settings, scrape metrics, optionally add it to a Docker Compose stack, and add a Prometheus job.

### Launch Exporter

First run the exporter as follows:

```bash
docker run \
    --rm -it \
    -p 9469:9469 \
    brendonmatheson/prometheus-librespeed-exporter:1.0.0
```

Note that by default `librespeed-cli` will automatically select a server to use if you don't specify one.   We will see how to specify servers later.

Now in a different terminal test that it is able to yield metrics with `curl`:

```bash
curl http://localhost:9469/probe?script=librespeed
```

Note that this command will take up to a minute to complete as it actually performing the speed test before it returns the results.  Once complete you should see result:

```
$ curl http://localhost:9469/probe?script=librespeed

# HELP script_success Script exit status (0 = error, 1 = success).
# TYPE script_success gauge
script_success{script="librespeed"} 1
# HELP script_duration_seconds Script execution time, in seconds.
# TYPE script_duration_seconds gauge
script_duration_seconds{script="librespeed"} 55.734358
# HELP script_exit_code The exit code of the script.
# TYPE script_exit_code gauge
script_exit_code{script="librespeed"} 0
librespeed_bytes_sent{server="Singapore (Salvatore Cahyo)"} 61341664
librespeed_bytes_received{server="Singapore (Salvatore Cahyo)"} 34770600
librespeed_ping{server="Singapore (Salvatore Cahyo)"} 43.63636363636363
librespeed_jitter{server="Singapore (Salvatore Cahyo)"} 0.38
librespeed_download{server="Singapore (Salvatore Cahyo)"} 17.83
librespeed_upload{server="Singapore (Salvatore Cahyo)"} 31.44
```

### Run Exporter in Docker Compose

If you are using Docker Compose the equivalent service definition is:

```yaml
  librespeed_exporter:
    image: "brendonmatheson/prometheus-librespeed-exporter:1.0.0"
    ports:
      - "9469:9469"
    restart: "always"
```

### Prometheus Job

Now add a job to your Prometheus configuration:

```yaml
  - job_name: "librespeed"
    metrics_path: /probe
    params:
      script: [librespeed]
    static_configs:
      - targets:
          - myexporterhostname:9469
    scrape_interval: 360m
    scrape_timeout: 2m
```

Since the test can take some time (up to a minute for a single scan from our observations) ensure that the timeout allows for this.  Also consider running the test infrequently to avoid generating large data transfers.  the `librespeed_bytes_sent` and `librespeed_bytes_received` metrics give you visibility on the volume of data transferred during the test.

Also note that testing your configuration may be difficult when you have a long scrape_interval like 360 minutes as above, so you may want to start with a short interval such as 2 minutes.

## Custom Servers

### Introduction

In addition to the librespeed-cli which is the basis for this Prometheus exporter, the librespeed project also offer a self-hostable speedtest server and the CLI can be configured to use custom servers instead of public servers.  This can be useful for measuring performance across private networks.

### Speedtest Server

To run a speedtest server you can use the command line:

```bash
docker run --rm -it adolfintel/speedtest:5.2.4
```

If you use docker-compose then you can use a service entry such as the following:

```yaml
librespeed_service:
    image: "adolfintel/speedtest:5.2.4"
    ports:
      - "80:80"
    restart: "always"
```

See the [librespeed / speedtest](https://github.com/librespeed/speedtest/blob/master/doc_docker.md) project for comprehensive documentation.

### Backends

Next you will need to create a JSON file that provides the details of your custom server (or servers) so that the exporter knows where to find them.

In the following example we are running two different private speedtest servers, and register them in our custom backends file with the names "bkk80" and "hea92":

```json
[
  {
    "id": 80,
    "name": "bkk80",
    "server": "http://speedtest.bkk80.aleisium.com/",
    "dlURL": "backend/garbage.php",
    "ulURL": "backend/empty.php",
    "pingURL": "backend/empty.php",
    "getIpURL": "backend/getIP.php"
  },
  {
    "id": 92,
    "name": "hea92",
    "server": "http://speedtest.hea92.aleisium.com/",
    "dlURL": "backend/garbage.php",
    "ulURL": "backend/empty.php",
    "pingURL": "backend/empty.php",
    "getIpURL": "backend/getIP.php"
  }
]
```

See the [librespeed / speedtest-cli documentation](https://github.com/librespeed/speedtest-cli#use-a-custom-backend-server-list) for additional details.

### Run the Exporter

We must now mount the backends JSON into the exporter, and specify the servers we want it to use via an environment variable, unless we want it to automatically select the server.

Command-line launch will now be as follows:

```bash
docker run \
    --rm -it \
    --env SERVER_IDS=80|92
    -p 9469:9469 \
    -v $(pwd)/librespeed-backends.json:/librespeed-backends.json \
    brendonmatheson/prometheus-librespeed-exporter:1.0.0
```

Note the backends file can be named anything you like, but must be mounted at `/librespeed-backends.json`.

The equivalent Docker Compose service definition is:

```yaml
librespeed_exporter:
    environment:
      - "SERVER_IDS=80|92"
    image: "brendonmatheson/prometheus-librespeed-exporter:1.0.0"
    ports:
      - "9469:9469"
    restart: "always"
    volumes:
      - "./librespeed-backends.json:/librespeed-backends.json"
```

### Configure Prometheus Job

The Prometheus job is the same as for our Quick Start:

```yaml
  - job_name: "librespeed"
    metrics_path: /probe
    params:
      script: [librespeed]
    static_configs:
      - targets:
          - myexporterhostname:9469
    scrape_interval: 360m
    scrape_timeout: 4m
```

Note that now that we are running two speedtests for each probe, we have doubled the timeout.

## Disable Download and / or Upload

The `librespeed-cli` offers `--no-download` and `--no-upload` switches which can be applied to the exporter by setting the `PERFORM_DOWNLOAD` and `PERFORM_UPLOAD` environment variables to `FALSE`.

For example the following Docker Compose service entry will run the exporter but only perform download tests upon each probe:

```yaml
librespeed_exporter:
    environment:
      - "SERVER_IDS=80|92"
      - "PERFORM_UPLOAD=FALSE"
    image: "brendonmatheson/prometheus-librespeed-exporter:1.0.0"
    ports:
      - "9469:9469"
    restart: "always"
    volumes:
      - "./librespeed-backends.json:/librespeed-backends.json"
```

The `librespeed_upload` metric will be omitted from the probe results:

```
# HELP script_success Script exit status (0 = error, 1 = success).
# TYPE script_success gauge
script_success{script="librespeed"} 1
# HELP script_duration_seconds Script execution time, in seconds.
# TYPE script_duration_seconds gauge
script_duration_seconds{script="librespeed"} 94.033419
# HELP script_exit_code The exit code of the script.
# TYPE script_exit_code gauge
script_exit_code{script="librespeed"} 0
librespeed_bytes_sent{server="bkk80"} 0
librespeed_bytes_received{server="bkk80"} 166673450
librespeed_ping{server="bkk80"} 6.2727272727272725
librespeed_jitter{server="bkk80"} 1
librespeed_download{server="bkk80"} 85.44
```

## Building

### Architecture Support

This image has been developed and tested on 32-bit Raspbian (armv7) and 64-bit Debian (amd64).

Other architectures may work, or may require additional changes to the Dockerfile to correctly map the arch tags to the names of the librespeed-cli and script_exporter binaries that are downloaded.

### Building Locally

To build from source, use the convenience script:

```bash
./build-local.sh

$ ./build-local.sh

Sending build context to Docker daemon  103.4kB
Step 1/11 : ARG TARGET_ARCH=
Step 2/11 : FROM ${TARGET_ARCH}alpine:3.15.0
 ---> c059bfaa849c

...

Successfully tagged brendonmatheson/prometheus-librespeed-exporter:latest-local
```

Note the image is tagged as `latest-local`.

### Multi-Arch Image Build

The image published to Docker Hub was built using `docker buildx` as follows:

```bash
sudo docker buildx create --name builder --use

sudo docker buildx build \
    --platform linux/arm/v7,linux/amd64 \
    --output=type=image,push=true \
    -t brendonmatheson/prometheus-librespeed-exporter:1.0.0 .
```
