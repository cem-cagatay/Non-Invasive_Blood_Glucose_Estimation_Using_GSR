# KUlucoseTrack

A wearable, non-invasive blood glucose monitoring system using Galvanic Skin Response (GSR) and a Flutter mobile app for real-time tracking and notifications.
**This project was completed as the senior design project for the ELEC 491 course at Koç University.**

---

## Overview

KUlucoseTrack combines a custom GSR sensor on an Arduino Nano ESP32 with a cross-platform Flutter app. 
The device measures skin conductance, applies a linear regression model on-board to estimate blood glucose, then streams results over Bluetooth Low Energy (BLE) to the mobile app every 1–2 seconds. 
The app displays real-time graphs, persists in the background, and sends high/low alerts.

---

## Hardware

- **GSR Sensor Circuit**  
  - Two Ag/AgCl electrodes, signal amplifier, and noise-filtering stage  
  - Compact PCB (1.85 × 4 cm) designed in KiCAD  
- **Microcontroller**  
  - Arduino Nano ESP32 for signal acquisition, on-board ML inference, and BLE communication  
- **Power & Connectivity**  
  - Stable 3.3 V supply section on PCB  
  - I²C pins available for future expansion :contentReference[oaicite:0]{index=0}

---

## Arduino Firmware

1. **Dependencies**  
   - `ArduinoJson`, `BLEDevice`, `BLEServer`, `BLEUtils`, `BLE2902`  
2. **Data Flow**  
   1. `analogRead(GSR)` → convert to voltage  
   2. Apply linear model: `bloodSugar = round(-87 * voltage + 180)`  
   3. Serialize JSON and notify connected client every second  
3. **Usage**  
   ```bash
   # Install ESP32 board support in Arduino IDE
   # Open `arduino/ble_gsr.ino` and upload to Nano ESP32
