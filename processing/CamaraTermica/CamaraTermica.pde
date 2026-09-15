// ============================================================
//  GY-MCU90640 - Visualizador térmico en Processing
//  Requiere: instalar librería "Serial" (viene incluida)
// ============================================================

import processing.serial.*;

// --- Configuración ---
final int COLS        = 32;
final int ROWS        = 20;
final int PIXELS      = COLS * ROWS;
final int CELL_SIZE   = 20;       // Tamaño de cada píxel en pantalla (px)
final int PANEL_W     = 250;      // Ancho del panel lateral de info
final float TEMP_UNIT = 0.01;

// Serial port selection:
// - Set SERIAL_PORT_NAME to an exact value from the console output to force a port.
// - Or set SERIAL_PORT_INDEX to one of the printed indexes.
// - Leave both unset to auto-connect only when exactly one port is available.
final String SERIAL_PORT_NAME = "";
final int SERIAL_PORT_INDEX   = -1;

// Colores del mapa térmico (frío → caliente)
// Negro → Violeta → Azul → Cyan → Verde → Amarillo → Rojo → Blanco
color[] PALETTE;

Serial port;
float[] temps    = new float[PIXELS];
float   ambient  = 0;
float   minT     = 0, maxT = 0, avgT = 0;
int     minIdx   = 0, maxIdx = 0;
boolean frameReady = false;
boolean serialConnected = false;
String  serialStatus = "Serial port not selected";

// Buffer de recepción
byte[]  rxBuf    = new byte[2 + PIXELS * 2 + 2];
int     rxIdx    = 0;
boolean synced   = false;
int     prevByte = 0;

// FPS
int     lastFrameTime = 0;
float   fps = 0;

void settings() {
  size(COLS * CELL_SIZE + PANEL_W, ROWS * CELL_SIZE);
}

// ============================================================
void setup() {
  // Quitar el size() que había antes, ahora va en settings()
  textFont(createFont("Monospaced", 13));
  colorMode(RGB, 255);

  buildPalette();

  String[] ports = Serial.list();
  println("Puertos serie disponibles:");
  for (int i = 0; i < ports.length; i++) {
    println("  [" + i + "] " + ports[i]);
  }

  String portName = selectSerialPort(ports);
  if (portName == null) {
    println(serialStatus);
    return;
  }

  try {
    println("Conectando a: " + portName);
    port = new Serial(this, portName, 115200);
    serialConnected = true;
    serialStatus = "Connected to " + portName;
  } catch (RuntimeException e) {
    serialStatus = "Could not open serial port: " + portName;
    println(serialStatus);
    println(e.getMessage());
  }
}

String selectSerialPort(String[] ports) {
  if (SERIAL_PORT_NAME != null && SERIAL_PORT_NAME.trim().length() > 0) {
    return SERIAL_PORT_NAME.trim();
  }

  if (SERIAL_PORT_INDEX >= 0) {
    if (SERIAL_PORT_INDEX < ports.length) {
      return ports[SERIAL_PORT_INDEX];
    }
    serialStatus = "SERIAL_PORT_INDEX " + SERIAL_PORT_INDEX + " is out of range. Edit SERIAL_PORT_INDEX or SERIAL_PORT_NAME.";
    return null;
  }

  if (ports.length == 1) {
    return ports[0];
  }

  if (ports.length == 0) {
    serialStatus = "No serial ports found. Connect the ESP32 and restart the sketch.";
  } else {
    serialStatus = "Multiple serial ports found. Set SERIAL_PORT_INDEX or SERIAL_PORT_NAME at the top of CamaraTermica.pde.";
  }
  return null;
}

// ============================================================
void draw() {
  if (!serialConnected) {
    drawSerialStatus();
    return;
  }

  // Solo redibujar si llegó un frame nuevo, evita el parpadeo
  if (frameReady) {
    background(15);
    drawHeatMap();
    drawInfo();
    frameReady = false;
  }
}

void drawSerialStatus() {
  background(15);
  fill(230);
  textAlign(LEFT, TOP);
  textSize(14);
  text("Thermal viewer", 20, 20);
  textSize(12);
  text(serialStatus, 20, 55, width - 40, height - 80);
  text("Check the console for available serial ports, then edit SERIAL_PORT_INDEX or SERIAL_PORT_NAME.", 20, 105, width - 40, height - 130);
}

// ============================================================
//  Leer bytes del puerto serie
// ============================================================
void serialEvent(Serial p) {
  while (p.available() > 0) {
    int b = p.read() & 0xFF;

    // Buscar magic bytes 0xAB 0xCD para sincronizar
    if (!synced) {
      if (prevByte == 0xAB && b == 0xCD) {
        synced = true;
        rxIdx  = 0;
      }
      prevByte = b;
      continue;
    }

    // Llenar buffer del frame
    rxBuf[rxIdx++] = (byte)b;

    if (rxIdx >= rxBuf.length) {
      // Frame completo recibido
      parseFrame();
      synced  = false;
      rxIdx   = 0;
      prevByte = 0;
    }
  }
}

// ============================================================
//  Parsear frame recibido
// ============================================================
void parseFrame() {
  minT = Float.MAX_VALUE;
  maxT = -Float.MAX_VALUE;
  float sum = 0;

  for (int i = 0; i < PIXELS; i++) {
    int lo  = rxBuf[i * 2]     & 0xFF;
    int hi  = rxBuf[i * 2 + 1] & 0xFF;
    float t = (lo | (hi << 8)) * TEMP_UNIT;
    temps[i] = t;
    if (t < minT) { minT = t; minIdx = i; }
    if (t > maxT) { maxT = t; maxIdx = i; }
    sum += t;
  }
  avgT = sum / PIXELS;

  int ambLo = rxBuf[PIXELS * 2]     & 0xFF;
  int ambHi = rxBuf[PIXELS * 2 + 1] & 0xFF;
  ambient   = (ambLo | (ambHi << 8)) * TEMP_UNIT;

  // Calcular FPS
  int now = millis();
  fps = 1000.0 / max(1, now - lastFrameTime);
  lastFrameTime = now;

  frameReady = true;
}

// ============================================================
//  Dibujar mapa térmico
// ============================================================
void drawHeatMap() {
  float range = maxT - minT;
  if (range < 0.1) range = 0.1;

  for (int row = 0; row < ROWS; row++) {
    for (int col = 0; col < COLS; col++) {
      float t   = temps[row * COLS + col];
      float norm = constrain((t - minT) / range, 0, 1);
      color c   = tempToColor(norm);

      fill(c);
      noStroke();
      rect(col * CELL_SIZE, row * CELL_SIZE, CELL_SIZE, CELL_SIZE);
    }
  }

  // Marcar punto mínimo (azul)
  int minRow = minIdx / COLS, minCol = minIdx % COLS;
  drawMarker(minCol * CELL_SIZE + CELL_SIZE/2, minRow * CELL_SIZE + CELL_SIZE/2,
             color(100, 180, 255), minT);

  // Marcar punto máximo (rojo)
  int maxRow = maxIdx / COLS, maxCol = maxIdx % COLS;
  drawMarker(maxCol * CELL_SIZE + CELL_SIZE/2, maxRow * CELL_SIZE + CELL_SIZE/2,
             color(255, 80, 80), maxT);
}

void drawMarker(float x, float y, color c, float temp) {
  stroke(c);
  strokeWeight(2);
  noFill();
  ellipse(x, y, 14, 14);
  fill(c);
  noStroke();
  textAlign(LEFT, BOTTOM);
  textSize(10);
  text(nf(temp, 2, 1) + "C", x + 8, y);
}

// ============================================================
//  Panel lateral de información
// ============================================================
void drawInfo() {
  int px = COLS * CELL_SIZE + 20;
  int py = 30;
  int lh = 28;

  // Fondo del panel lateral ajustado a la altura real
  fill(30);
  noStroke();
  rect(COLS * CELL_SIZE, 0, PANEL_W, ROWS * CELL_SIZE);

  textAlign(LEFT, TOP);

  // Título
  fill(220, 220, 80);
  textSize(15);
  text("Sensor de temperatura", px, py);
  fill(140);
  textSize(11);
  text("MLX90640 IR GY-MCU90640", px, py + 20);
  py += 55;

  // Datos de temperatura
  textSize(13);
  labelValue("Ambiente:", nf(ambient, 2, 2) + " C", px, py, color(200, 200, 255)); py += lh;
  labelValue("Minima:  ", nf(minT, 2, 2) + " C", px, py, color(100, 180, 255));    py += lh;
  labelValue("Maxima:  ", nf(maxT, 2, 2) + " C", px, py, color(255, 100, 100));    py += lh;
  labelValue("Promedio:", nf(avgT, 2, 2) + " C", px, py, color(100, 220, 120));    py += lh;
  labelValue("Delta:   ", nf(maxT - minT, 2, 2) + " C", px, py, color(255, 200, 100)); py += lh * 1.5;

  // FPS
  labelValue("FPS:     ", nf(fps, 1, 1), px, py, color(180, 180, 180)); py += lh * 1.5;

  // Barra de color (leyenda)
  py += 10;
  fill(180);
  textSize(11);
  text("Escala termica:", px, py); py += 18;

  for (int i = 0; i < 100; i++) {
    float norm = i / 100.0;
    stroke(tempToColor(norm));
    line(px + i * 2, py, px + i * 2, py + 20);
  }
  noStroke();
  fill(100, 180, 255);
  textSize(10); textAlign(LEFT, TOP);
  text(nf(minT, 2, 1), px, py + 22);
  fill(255, 100, 100);
  textAlign(RIGHT, TOP);
  text(nf(maxT, 2, 1), px + 200, py + 22);
  py += 50;

  // Retícula de posición del máximo
  textAlign(LEFT, TOP);
  fill(160);
  textSize(11);
  text("Max en: fila=" + (maxIdx/COLS) + " col=" + (maxIdx%COLS), px, py); py += lh;
  text("Min en: fila=" + (minIdx/COLS) + " col=" + (minIdx%COLS), px, py);
}

void labelValue(String label, String value, int x, int y, color valColor) {
  fill(160);
  text(label, x, y);
  fill(valColor);
  text(value, x + 95, y);
}

// ============================================================
//  Paleta de colores (Iron/Thermal clásica)
// ============================================================
void buildPalette() {
  PALETTE = new color[256];
  for (int i = 0; i < 256; i++) {
    float t = i / 255.0;
    PALETTE[i] = ironColor(t);
  }
}

color tempToColor(float norm) {
  int idx = (int)constrain(norm * 255, 0, 255);
  return PALETTE[idx];
}

// Paleta "Iron" (igual a cámaras térmicas reales)
color ironColor(float t) {
  // Segmentos: negro→azul→violeta→rojo→naranja→amarillo→blanco
  float r, g, b;
  if (t < 0.25) {
    float s = t / 0.25;
    r = 0; g = 0; b = s;
  } else if (t < 0.5) {
    float s = (t - 0.25) / 0.25;
    r = s * 0.8; g = 0; b = 1 - s * 0.5;
  } else if (t < 0.75) {
    float s = (t - 0.5) / 0.25;
    r = 0.8 + s * 0.2; g = s * 0.6; b = 0.5 - s * 0.5;
  } else {
    float s = (t - 0.75) / 0.25;
    r = 1; g = 0.6 + s * 0.4; b = s;
  }
  return color(r * 255, g * 255, b * 255);
}
