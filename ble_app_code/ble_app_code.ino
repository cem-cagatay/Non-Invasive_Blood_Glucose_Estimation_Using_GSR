#include <ArduinoJson.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#define GSR A0

#define SERVICE_UUID "87e3a34b-5a54-40bb-9d6a-355b9237d42b"
#define CHARACTERISTIC_UUID "cdc7651d-88bd-4c0d-8c90-4572db5aa14b"
#define SERVERNAME "Blood Sugar Monitor"

BLEServer* pServer = NULL;
BLEService* pService = NULL;
BLECharacteristic* voltageCharacteristic = NULL;
BLEAdvertising* pAdvertising = NULL;

bool deviceConnected = false;
float conductiveVoltage = 0.0;
int bloodSugar = 0;
int sensorValue = 0;

DynamicJsonDocument sendDoc(1024);

class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
    Serial.println("Device: Connected!");
  };

  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
    Serial.println("Device: Disconnected!");
    BLEDevice::startAdvertising();
  }
};

void setupBle() {
  Serial.println("BLE initializing...");
  BLEDevice::init(SERVERNAME);

  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  pService = pServer->createService(SERVICE_UUID);
  voltageCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_READ
  );

  voltageCharacteristic->addDescriptor(new BLE2902());

  pService->start();

  pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x12);

  BLEDevice::startAdvertising();

  Serial.println("BLE initialized. Waiting for client to connect...");
}

void readVoltage() {
  sensorValue = analogRead(GSR);
  conductiveVoltage = sensorValue * (3.3 / 4095.0); // Assuming 3.3V reference and 12-bit ADC
  delay(1000);
  Serial.print("Conductive Voltage: ");
  Serial.println(conductiveVoltage);
}

void calculateBloodSugar() {
  // y = -87x + 180
  bloodSugar = round(-87 * conductiveVoltage + 180);
}

void sendData() {
  sendDoc["bloodSugar"] = bloodSugar;

  String data;
  serializeJson(sendDoc, data);
  Serial.println("Sending Data: " + data);

  voltageCharacteristic->setValue(data.c_str());
  voltageCharacteristic->notify();
}

void setup() {
  Serial.begin(115200);
  pinMode(GSR, INPUT);
  setupBle();
}

void loop() {
  readVoltage();
  calculateBloodSugar();

  if (deviceConnected) {
    sendData();
    delay(1000); // Send data every second
  }
}