#!/usr/bin/env python3
import ssl

import paho.mqtt.client as mqtt

MOSQUITTO = {
	"host": "mosquitto",
	"port": 8883,
	"topic": "esp32/sensors",
}

THINGSBOARD = {
	"host": "thingsboard",
	"port": 8883,
	"token": "your-device-token-here",
	"topic": "v1/devices/me/telemetry",
}


def tls_mtls():
	"""mTLS: verify server and present client cert."""
	ctx = ssl.create_default_context(ssl.Purpose.SERVER_AUTH)
	ctx.load_verify_locations("/certs/ca.crt")
	ctx.load_cert_chain("/certs/client.crt", "/certs/client.key")
	return ctx


def tls_server_only():
	"""Server-only TLS: verify server cert."""
	ctx = ssl.create_default_context(ssl.Purpose.SERVER_AUTH)
	ctx.load_verify_locations("/certs/ca.crt")
	return ctx


def on_tb_connect(client, userdata, flags, rc):
	if rc == 0:
		print("[TB] Connected")
	else:
		print(f"[TB] Connection failed rc={rc}")


def on_tb_disconnect(client, userdata, rc):
	if rc != 0:
		print(f"[TB] Unexpected disconnect rc={rc}, will retry")


def on_mosquitto_connect(client, userdata, flags, rc):
	if rc == 0:
		print("[MQTT] Connected")
		client.subscribe(MOSQUITTO["topic"])
	else:
		print(f"[MQTT] Connection failed rc={rc}")


def on_mosquitto_disconnect(client, userdata, rc):
	if rc != 0:
		print(f"[MQTT] Unexpected disconnect rc={rc}, will retry")


def on_mosquitto_message(client, userdata, msg):
	try:
		payload = msg.payload.decode()
		print(f"[MQTT] Received: {payload}")
		result = tb_client.publish(THINGSBOARD["topic"], payload, qos=1)
		if result.rc == mqtt.MQTT_ERR_SUCCESS:
			print("[TB] Forwarded")
		else:
			print(f"[TB] Publish failed rc={result.rc}")
	except Exception as e:
		print(f"[ERROR] {e}")


tb_client = mqtt.Client(client_id="tb-bridge")
tb_client.on_connect = on_tb_connect
tb_client.on_disconnect = on_tb_disconnect
tb_client.tls_set_context(tls_server_only())
tb_client.reconnect_delay_set(min_delay=1, max_delay=30)

tb_client.username_pw_set(THINGSBOARD["token"])
tb_client.connect(THINGSBOARD["host"], THINGSBOARD["port"], keepalive=60)
tb_client.loop_start()


mosquitto_client = mqtt.Client(client_id="mosquitto-bridge")
mosquitto_client.on_connect = on_mosquitto_connect
mosquitto_client.on_disconnect = on_mosquitto_disconnect
mosquitto_client.tls_set_context(tls_mtls())
mosquitto_client.reconnect_delay_set(min_delay=1, max_delay=30)

mosquitto_client.on_message = on_mosquitto_message
mosquitto_client.connect(MOSQUITTO["host"], MOSQUITTO["port"], keepalive=60)

print(f"Bridge running: {MOSQUITTO['topic']} → ThingsBoard")
mosquitto_client.loop_forever()
