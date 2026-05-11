#include <WiFi.h>
#include <PubSubClient.h>
#include <Wire.h>
#include <Adafruit_BMP085.h>

const char* wifi_ssid = "";
const char* wifi_password = "";
const char* mqtt_server_broker = "192.168.1.146";

WiFiClient esp_wifi_client;
PubSubClient client(esp_wifi_client);

Adafruit_BMP085 bmp;

/*
 * Analog PIN configuration
 * */
#define MQ2_PIN      34   // ADC1
#define LED_VERTE    2
#define LED_ORANGE   4
#define LED_ROUGE    5

/*
 * MIN/MAX value for each sensor
 * */
#define GAS_MAX          1500
#define TEMP_MIN         -10.0
#define TEMP_MAX         50.0
#define PRESSURE_MIN     950.0
#define PRESSURE_MAX     1050.0

/*
 * Timing publish interval
 * */
unsigned long last_publish_time = 0;
const long PUBLISH_INTERVAL = 3000;


void setup_LEDs() {
  pinMode(LED_VERTE, OUTPUT);
  pinMode(LED_ORANGE, OUTPUT);
  pinMode(LED_ROUGE, OUTPUT);
  all_LEDs_off();
}

void all_LEDs_off() {
  digitalWrite(LED_VERTE, LOW);
  digitalWrite(LED_ORANGE, LOW);
  digitalWrite(LED_ROUGE, LOW);
}

void set_LED_status(bool mqtt_ok, bool sensors_ok) {
  all_LEDs_off();

  if (!mqtt_ok) {
    digitalWrite(LED_ROUGE, HIGH);
  } else if (sensors_ok) {
    // mqtt works but sensors don't
    digitalWrite(LED_VERTE, HIGH);
  } else {
    // nothing works
    digitalWrite(LED_ORANGE, HIGH);
  }
}

bool check_atmosphere(float temperature, float pressure, int gas) {
  bool is_temperature_nice = (temperature >= TEMP_MIN && temperature <= TEMP_MAX);
  bool is_pressure_normal = (pressure >= PRESSURE_MIN && pressure <= PRESSURE_MAX);
  bool is_gas_minimal = (gas <= GAS_MAX);

  if (!is_temperature_nice) Serial.println("!! Extreme temperature");
  if (!is_pressure_normal) Serial.println("!! Pressure not normal");
  if (!is_gas_minimal) Serial.println("!! Gaz detected");

  return (is_temperature_nice && is_pressure_normal && is_gas_minimal);
}

void setup_wifi() {
  Serial.print("Connecting WiFi");
  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");

    set_LED_status(false, false);
  }

  Serial.println("\nWiFi connected");
  Serial.println(WiFi.localIP());
}

void mqtt_reconnect() {
  while (!client.connected()) {
    Serial.print("Connecting MQTT...");

    set_LED_status(false, false);

    if (client.connect("LOCAL_MOSQUITTO")) {
      Serial.println("connected");
    } else {
      Serial.print("failed, rc=");
      Serial.println(client.state());

      delay(2000);
    }
  }
}

void setup() {
  Serial.begin(9600);

  setup_LEDs();
  setup_wifi();

  client.setServer(mqtt_server, 1883);

  // SDA and SCL
  Wire.begin(21, 22);

  if (!bmp.begin()) {
    Serial.println("- [X] BMP180 not found");
  } else {
    Serial.println("- BMP180 OK");
  }
}

void loop() {
  if (!client.connected()) {
    mqtt_reconnect();
  }
  client.loop();

  int gas_value = analogRead(MQ2_PIN);
  float temperature = bmp.readTemperature();

  // and convert to hecto-pascal by dividing by 100
  float pressure = bmp.readPressure() / 100.0;

  bool sensors_ok = check_atmosphere(temperature, pressure, gas_value);
  bool mqtt_ok = client.connected();

  // update LEDs
  set_LED_status(mqtt_ok, sensors_ok);

  /*
   * Publish retrieved values periodically to MQTT
   * but first check the last time we published to MQTT
   * */
  if (millis() - last_publish_time >= PUBLISH_INTERVAL) {
    last_publish_time = millis();

    // then publish
    String payload = "{";
    payload += "\"gas\":" + String(gas_value);
    payload += ",\"temperature\":" + String(temperature, 1);
    payload += ",\"pressure\":" + String(pressure, 1);
    payload += ",\"sensors_ok\":" + String(sensors_ok ? "true" : "false");
    payload += "}";

    Serial.println("- Publishing: " + payload);

    boolean published = client.publish("esp32/sensors", payload.c_str());
    if (!published) {
      Serial.println("- [X] Failed to publish to MQTT");
    }
  }

  delay(100);
}
