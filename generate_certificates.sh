#!/usr/bin/env bash

set -euo pipefail

mkdir -p certificates

# CA
openssl genrsa -des3 -out certificates/ca.key 4096
openssl req -new -x509 -days 3650 -key certificates/ca.key \
  -out certificates/ca.crt \
  -subj "/CN=Mandrindra_GCP_CA" \
  -addext "basicConstraints=critical,CA:TRUE" \
  -addext "keyUsage=critical,keyCertSign,cRLSign"

# Mosquitto
openssl genrsa -out certificates/mosquitto-server.key 2048
openssl req -new -key certificates/mosquitto-server.key -out certificates/mosquitto-server.csr -subj "/CN=mosquitto"

openssl x509 -req -days 365 \
  -in certificates/mosquitto-server.csr -CA certificates/ca.crt -CAkey certificates/ca.key -CAcreateserial \
  -out certificates/mosquitto-server.crt -sha256 \
  -extfile <(printf "subjectAltName=DNS:mosquitto,IP:192.168.36.30")


# ThingsBoard
openssl ecparam -out certificates/thingsboard-server.key -name secp256r1 -genkey
openssl req -new -key certificates/thingsboard-server.key -out certificates/thingsboard-server.csr -subj "/CN=thingsboard"

openssl x509 -req -days 365 \
  -in certificates/thingsboard-server.csr -CA certificates/ca.crt -CAkey certificates/ca.key -CAcreateserial \
  -out certificates/thingsboard-server.crt \
  -extfile <(printf "subjectAltName=DNS:thingsboard")


# Gateway client
openssl genrsa -out certificates/client.key 2048
openssl req -new -key certificates/client.key -out certificates/client.csr -subj "/CN=gateway-client"

openssl x509 -req -days 365 \
  -in certificates/client.csr -CA certificates/ca.crt -CAkey certificates/ca.key -CAcreateserial \
  -out certificates/client.crt -sha256

cat certificates/thingsboard-server.crt certificates/ca.crt > certificates/thingsboard-chain.crt

# ESP32 client
openssl genrsa -out certificates/esp32-client.key 2048
openssl req -new -key certificates/esp32-client.key -out certificates/esp32-client.csr -subj "/CN=esp32-client"

openssl x509 -req -days 365 \
  -in certificates/esp32-client.csr -CA certificates/ca.crt -CAkey certificates/ca.key -CAcreateserial \
  -out certificates/esp32-client.crt -sha256


# Force PKCS#1 format — ESP32 mbedTLS requires this
openssl rsa -in certificates/esp32-client.key -out certificates/esp32-client-rsa.key
mv certificates/esp32-client-rsa.key certificates/esp32-client.key

chmod 644 certificates/*.crt certificates/*.key

echo "[All done.]\_(:D)-|--<"
