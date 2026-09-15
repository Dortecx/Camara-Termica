# Wiring

## GY-MCU90640 UART thermal sensor

| GY-MCU90640 | ESP32 |
| --- | --- |
| TX | GPIO16 / RX2 |
| RX | GPIO17 / TX2 |
| GND | GND |
| VCC | Module-rated supply |

The Arduino sketch uses:

```cpp
Serial1.begin(115200, SERIAL_8N1, 16, 17);
```

Open `arduino/CamaraTermica/CamaraTermica.ino` for the bridge source.

## USB viewer link

Connect the ESP32 to the computer over USB. The Processing viewer opens the ESP32 USB serial port at `115200` baud and reads the binary packet described in [protocol.md](protocol.md).
