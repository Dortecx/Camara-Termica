// ============================================================
//  GY-MCU90640 - Adapted for ESP32
//  Sensor:     Serial1 -> RX=GPIO16, TX=GPIO17
//  Processing: Serial  -> USB, same bridge protocol
// ============================================================

#define SENSOR_BAUDRATE  115200

#define MLX_COLS          32
#define MLX_ROWS          20
#define MLX_PIXELS        (MLX_COLS * MLX_ROWS)  // 640

#define FRAME_HEADER_0    0x5A
#define FRAME_HEADER_1    0x5A
#define FRAME_HEADER_2    0x02
#define FRAME_HEADER_3    0x06
#define FRAME_TOTAL_SIZE  1330
#define FRAME_DATA_OFFSET 4
#define FRAME_TEMP_UNIT   0.01f
#define FRAME_AMBIENT_L   (FRAME_TOTAL_SIZE - 2)
#define FRAME_AMBIENT_H   (FRAME_TOTAL_SIZE - 1)

#define OUT_MAGIC_0  0xAB
#define OUT_MAGIC_1  0xCD

// Sensor pins on the ESP32 and Arduino MEGA, kept as in the source sketch.
#define SENSOR_RX_PIN  16   // GPIO16 (RX2) <- sensor TX
#define SENSOR_TX_PIN  17   // GPIO17 (TX2) -> sensor RX; not required when only listening

uint8_t  frameBuffer[FRAME_TOTAL_SIZE];
uint16_t rawPixels[MLX_PIXELS];
uint16_t rawAmbient = 0;

// ============================================================
int readByteTimeout(uint16_t ms = 300) {
  unsigned long t = millis();
  while (!Serial1.available()) {
    if (millis() - t > ms) return -1;
  }
  return Serial1.read();
}

// ============================================================
bool readFrame() {
  while (true) {
    int b;
    b = readByteTimeout(2000); if (b < 0)               return false;
    if (b != FRAME_HEADER_0)   continue;
    b = readByteTimeout(200);  if (b != FRAME_HEADER_1)  continue;
    b = readByteTimeout(200);  if (b != FRAME_HEADER_2)  continue;
    b = readByteTimeout(200);  if (b != FRAME_HEADER_3)  continue;
    break;
  }

  frameBuffer[0] = FRAME_HEADER_0; frameBuffer[1] = FRAME_HEADER_1;
  frameBuffer[2] = FRAME_HEADER_2; frameBuffer[3] = FRAME_HEADER_3;

  for (uint16_t i = FRAME_DATA_OFFSET; i < FRAME_TOTAL_SIZE; i++) {
    int b = readByteTimeout(300);
    if (b < 0) return false;
    frameBuffer[i] = (uint8_t)b;
  }

  for (uint16_t i = 0; i < MLX_PIXELS; i++) {
    rawPixels[i] = (uint16_t)frameBuffer[FRAME_DATA_OFFSET + i * 2] |
                   ((uint16_t)frameBuffer[FRAME_DATA_OFFSET + i * 2 + 1] << 8);
  }

  rawAmbient = (uint16_t)frameBuffer[FRAME_AMBIENT_L] |
               ((uint16_t)frameBuffer[FRAME_AMBIENT_H] << 8);

  return true;
}

// ============================================================
void sendToProcessing() {
  Serial.write(OUT_MAGIC_0);
  Serial.write(OUT_MAGIC_1);

  for (uint16_t i = 0; i < MLX_PIXELS; i++) {
    Serial.write(rawPixels[i] & 0xFF);
    Serial.write((rawPixels[i] >> 8) & 0xFF);
  }

  Serial.write(rawAmbient & 0xFF);
  Serial.write((rawAmbient >> 8) & 0xFF);
}

// ============================================================
void setup() {
  Serial.begin(115200);   // USB to Processing
  while (!Serial && millis() < 3000);

  // ESP32: Serial1 with custom pins
  Serial1.begin(SENSOR_BAUDRATE, SERIAL_8N1, SENSOR_RX_PIN, SENSOR_TX_PIN);
  delay(500);

  while (Serial1.available()) Serial1.read();  // Clear initial buffer
  Serial.println("ESP32 listo. Esperando frames del sensor...");
}

// ============================================================
void loop() {
  if (readFrame()) {
    sendToProcessing();
  }
}
