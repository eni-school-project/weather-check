#!/usr/bin/env python3

import json
import paho.mqtt.client as mqtt

MOSQUITTO = {"host": "192.168.1.146", "port": 1883, "topic": "esp32/sensors"}
THINGSBOARD = {
    "host": "vps-host",
    "port": 1884,
    "token": "thingsboard-token",
    "topic": "v1/topic",
}


def on_mosquitto_msg(client, userdata, msg):
    try:
        payload = msg.payload.decode()
        print(f"- MOSQUITTO: {payload}")
        tb_client.publish(THINGSBOARD["topic"], payload, qos=1)
        print("- Forwarded to ThingsBoard")
    except Exception as e:
        print(f"- X Error: {e}")


# Destination
tb_client = mqtt.Client(client_id="tb-bridge")
tb_client.username_pw_set(THINGSBOARD["token"])
tb_client.connect(THINGSBOARD["host"], THINGSBOARD["port"], 60)
tb_client.loop_start()

# MOSQUITTO source
mosquitto_client = mqtt.Client(client_id="wokwi-bridge")
mosquitto_client.on_message = on_mosquitto_msg
mosquitto_client.connect(MOSQUITTO["host"], MOSQUITTO["port"], 60)
mosquitto_client.subscribe(MOSQUITTO["topic"])
print(f"- Bridge started: {MOSQUITTO['topic']} -> ThingsBoard")

mosquitto_client.loop_forever()
