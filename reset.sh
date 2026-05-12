#!/usr/bin/env bash

set -euo pipefail

podman-compose down

sudo rm -r certificates/*

sudo rm -r mosquitto/data/*
