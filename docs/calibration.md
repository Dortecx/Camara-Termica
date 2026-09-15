# Calibration

## Thermal sensor

The bridge and viewer interpret GY-MCU90640 raw values with:

```text
temperature_c = raw_value * 0.01
```

For better accuracy:

1. Compare the reported ambient value against a trusted thermometer.
2. Test at a known stable target temperature.
3. Record offsets by operating environment.
4. Avoid using the first frames after power-up as calibration references.

Any display offset should be applied in the viewer or downstream analysis without changing the bridge packet format documented in [protocol.md](protocol.md).
