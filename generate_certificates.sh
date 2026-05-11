#!/usr/bin/env bash

set -euo pipefail

# CA
openssl genrsa -des3 -out ca.key 4096
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt -subj "/CN=Mandrindra_GCP_CA"

# Mosquitto
openssl genrsa -out mosquitto-server.key 2048
openssl req -new -key mosquitto-server.key -out mosquitto-server.csr -subj "/CN=mosquitto"

openssl x509 -req -days 365 \
  -in mosquitto-server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out mosquitto-server.crt -sha256 \
  -extfile <(printf "subjectAltName=DNS:mosquitto")


# ThingsBoard
openssl genrsa -out thingsboard-server.key 2048
openssl req -new -key thingsboard-server.key -out thingsboard-server.csr -subj "/CN=thingsboard"

openssl x509 -req -days 365 \
  -in thingsboard-server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out thingsboard-server.crt -sha256 \
  -extfile <(printf "subjectAltName=DNS:thingsboard")


# Gateway client
openssl genrsa -out client.key 2048
openssl req -new -key client.key -out client.csr -subj "/CN=gateway-client"

openssl x509 -req -days 365 \
  -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out client.crt -sha256

echo "[All done.]\_(:D)-|--<"
