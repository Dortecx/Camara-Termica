# Serial protocol

`arduino/CamaraTermica/CamaraTermica.ino` reads each GY-MCU90640 UART frame and republishes a compact binary packet over USB serial for `processing/CamaraTermica/CamaraTermica.pde`.

## Sensor input frame

The ESP32 waits for this GY-MCU90640 header:

```text
0x5A 0x5A 0x02 0x06
```

It then reads a total frame size of `1330` bytes. Pixel data starts at byte offset `4`.

## Viewer output packet

USB serial settings:

- baud: `115200`
- framing: 8 data bits, no parity, 1 stop bit

Packet layout:

| Bytes | Meaning |
| --- | --- |
| `0xAB 0xCD` | packet magic |
| `1280` bytes | 640 little-endian `uint16_t` pixels for a 32 x 20 image |
| `2` bytes | little-endian `uint16_t` ambient reading |

## Temperature conversion

```text
temperature_c = raw_value * 0.01
```

The packet preserves the source frame ordering. The viewer maps 640 values into 32 columns by 20 rows.
