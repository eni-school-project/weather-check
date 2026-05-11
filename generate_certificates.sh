#!/usr/bin/env bash

set -euo pipefail

mkdir -p certificates

# CA
openssl genrsa -des3 -out certificates/ca.key 4096
openssl req -new -x509 -days 3650 -key certificates/ca.key -out certificates/ca.crt -subj "/CN=Mandrindra_GCP_CA"

# Mosquitto
openssl genrsa -out certificates/mosquitto-server.key 2048
openssl req -new -key certificates/mosquitto-server.key -out certificates/mosquitto-server.csr -subj "/CN=mosquitto"

openssl x509 -req -days 365 \
  -in certificates/mosquitto-server.csr -CA certificates/ca.crt -CAkey certificates/ca.key -CAcreateserial \
  -out certificates/mosquitto-server.crt -sha256 \
  -extfile <(printf "subjectAltName=DNS:mosquitto")


# ThingsBoard
openssl genrsa -out certificates/thingsboard-server.key 2048
openssl req -new -key certificates/thingsboard-server.key -out certificates/thingsboard-server.csr -subj "/CN=thingsboard"

openssl x509 -req -days 365 \
  -in certificates/thingsboard-server.csr -CA certificates/ca.crt -CAkey certificates/ca.key -CAcreateserial \
  -out certificates/thingsboard-server.crt -sha256 \
  -extfile <(printf "subjectAltName=DNS:thingsboard")


# Gateway client
openssl genrsa -out certificates/client.key 2048
openssl req -new -key certificates/client.key -out certificates/client.csr -subj "/CN=gateway-client"

openssl x509 -req -days 365 \
  -in certificates/client.csr -CA certificates/ca.crt -CAkey certificates/ca.key -CAcreateserial \
  -out certificates/client.crt -sha256

echo "[All done.]\_(:D)-|--<"
