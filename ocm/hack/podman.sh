#!/bin/bash

set -e

podman machine init || true
podman machine stop || true
podman machine set --cpus=10 --memory=1500 --disk-size=125
podman machine start

podman machine ssh sudo sysctl fs.inotify.max_user_instances=1280
podman machine ssh sudo sysctl fs.inotify.max_user_watches=655360
