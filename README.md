# FilamintFixer

ESP32-based automatic filament jam detector and unsticker for 3D printers. Detects when filament is jammed or pinched on the spool and mechanically yanks it free — no missed prints, no babysitting.

![Concept Drawing](Drawing.png)

## How It Works

A spring-loaded feed arm guides filament from the spool to the extruder through a grooved wheel. When filament flows normally, the arm floats at its rest angle. When filament jams on the spool, the extruder's pull increases tension on the spring, pulling the arm down. When the angle drops below a threshold, a servo activates and yanks the filament free.

### Key Features

- **Automatic jam detection** via potentiometer angle feedback (primary) and reed switch filament movement detection (secondary)
- **Servo detach/attach pattern** — feed arm servo is detached during normal printing so the arm floats freely with spring tension, only attaching to actuate
- **Adjustable spring tension** — second servo locks in position to set baseline spring tension
- **Serial command interface** for tuning parameters and pot calibration
- **3D printable** — OpenSCAD parametric models included for all mechanical parts

## Hardware

| Component | Qty | Purpose |
|-----------|-----|---------|
| ESP32-S3 | 1 | Controller (any ESP32 with ADC works) |
| MG996R servo | 2 | Feed arm + tension arm |
| 16mm rotary pot | 2 | Angle feedback (D-shaft, linear taper) |
| Reed switch | 1 | Filament movement detection |
| 6mm disc magnet | 1 | On guide wheel for reed switch |
| 625ZZ bearing | 2 | Guide wheel axle |
| Extension spring | 1 | Connects feed arm to tension arm |

## Building

This is a [PlatformIO](https://platformio.org/) project targeting ESP32-S3.

```bash
# Build
pio run -e freenove_esp32_s3_wroom

# Upload
pio run -t upload -e freenove_esp32_s3_wroom

# Monitor serial output
pio run -t monitor -e freenove_esp32_s3_wroom
```

## 3D Printed Parts

STL files are in the `cad/` directory. Source files are parametric OpenSCAD — edit `common.scad` to adjust dimensions for different servos or potentiometers.

| Part | File | Description |
|------|------|-------------|
| Base | `base.stl` | Holds both servos, pot mounts underneath, reed switch mount |
| Feed Arm | `feed_arm.stl` | 120mm arm with D-shaft bore, spring anchor, wheel axle |
| Tension Arm | `tension_arm.stl` | 50mm arm with D-shaft bore, spring anchor at tip |
| Guide Wheel | `guide_wheel.stl` | 25mm grooved wheel with 625ZZ bearing pockets |

To regenerate STLs from source:
```bash
cd cad
openscad -o base.stl base.scad
openscad -o feed_arm.stl feed_arm.scad
openscad -o tension_arm.stl tension_arm.scad
openscad -o guide_wheel.stl guide_wheel.scad
```

## Serial Commands

| Command | Description |
|---------|-------------|
| `u` | Manual unstick trigger |
| `t <angle>` | Set tension servo angle |
| `j <angle>` | Set jam threshold angle |
| `r <angle>` | Set rest angle |
| `c` | Pot calibration (prints raw ADC for 5 sec) |
| `s` | Print status |
| `h` | Help |

## License

MIT
