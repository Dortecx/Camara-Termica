# Wiring

## GY-MCU90640 UART thermal sensor

![ESP32 to GY-MCU90640 wiring diagram](wiring-diagram.svg)

| GY-MCU90640 | ESP32 |
| --- | --- |
| TX | GPIO16 / RX2 |
| RX | GPIO17 / TX2 |
| GND | GND |
| VCC | Module-rated supply |

These are the pins used by this project, not a fixed hardware requirement. If your ESP32 board or wiring needs different UART pins, change the constants in `arduino/CamaraTermica/CamaraTermica.ino`:

```cpp
#define SENSOR_RX_PIN  16
#define SENSOR_TX_PIN  17
```

The sketch passes those constants to `Serial1.begin(...)`.

Open `arduino/CamaraTermica/CamaraTermica.ino` for the bridge source.

## USB viewer link

Connect the ESP32 to the computer over USB. The Processing viewer opens the ESP32 USB serial port at `115200` baud and reads the binary packet described in [protocol.md](protocol.md).
