#!/usr/bin/env bash

set -euo pipefail

podman-compose up -d postgres

sleep 5

podman run --rm --network=weather-check_iot-network \
  -e SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/thingsboard \
  -e INSTALL_TB=true thingsboard/tb-node:4.3.1.1

podman-compose up -d --build

podman-compose logs -f thingsboard
