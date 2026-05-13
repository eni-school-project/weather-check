#!/usr/bin/env bash

set -euo pipefail

podman-compose down --volumes

sudo rm -r mosquitto/data/*
