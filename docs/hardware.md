# Hardware

## Thermal bridge parts

- ESP32 development board
- GY-MCU90640 UART thermal camera module
- USB cable for the computer running the Processing viewer
- Module-rated power wiring for the ESP32 and sensor board

## Arduino dependencies

- ESP32 board support for Arduino IDE
- Built-in ESP32 `Serial` / `Serial1` support

The bridge sketch is `arduino/CamaraTermica/CamaraTermica.ino`.

## Processing dependency

Install [Processing](https://processing.org/download) and open `processing/CamaraTermica/CamaraTermica.pde`. The viewer uses Processing's built-in Serial library.

## Handling note

Power the sensor only within its rated supply range and share ground between the sensor module and ESP32. Disconnect power before changing wiring.
