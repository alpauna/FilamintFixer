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

## Bill of Materials

### Electronics (DigiKey)

| Part | DigiKey P/N | Qty | ~Price | Notes |
|------|------------|-----|--------|-------|
| ESP32-S3-DEVKITC-1-N8R8 | [2768-ESP32-S3-DEVKITC-1-N8R8-ND](https://www.digikey.com/en/products/detail/espressif-systems/ESP32-S3-DEVKITC-1-N8R8/15295894) | 1 | $15.00 | 8MB Flash + 8MB PSRAM. Any ESP32 with ADC works |
| Standard Metal Gear Servo | [1528-1083-ND](https://www.digikey.com/en/products/detail/adafruit-industries-llc/1142/5154658) | 2 | $19.95 | Adafruit 1142. Or MG996R from Amazon (~$8/pair) |
| 10K Pot, D-shaft, Linear | [987-1308-ND](https://www.digikey.com/en/products/detail/tt-electronics-bi/P160KN-0QD15B10K/2408885) | 2 | $1.59 | TT Electronics P160KN-0QD15B10K. Must be "QD" (D-shaft) |
| Reed Switch, Glass, NO | [HE502-ND](https://www.digikey.com/en/products/detail/littelfuse-inc/MDSR-4-12-23/200302) | 1 | $1.50 | Littelfuse MDSR-4-12-23 |
| Neodymium Disc Magnet 6x3mm | [469-1017-ND](https://www.digikey.com/en/products/detail/radial-magnets-inc/8996/5126078) | 1 | $0.30 | Radial Magnets 8996 |
| 625ZZ Ball Bearing | [1188-BEARING-625ZZ-ND](https://www.digikey.com/en/products/detail/olimex-ltd/BEARING-625ZZ/21662104) | 2 | $0.82 | 5mm bore, 16mm OD, 5mm width |

### Mechanical (Amazon / McMaster-Carr)

| Part | Qty | ~Price | Notes |
|------|-----|--------|-------|
| Extension spring, 30-50mm, light tension | 1 | $3 | Connects feed arm to tension arm |
| M5x30mm bolt + nut | 1 | $0.50 | Guide wheel axle |
| M3/M4 screw & nut assortment | 1 kit | $12 | Mounting hardware |

**Estimated total: $45-55** (with Amazon MG996R servos) or **~$85** (all from DigiKey)

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
| Base | `base.stl` | Holds both servos side-by-side, pot mounting pads, reed switch mount |
| Feed Arm | `feed_arm.stl` | 120mm arm with 25T spline bore, spring anchor, wheel axle, filament retainer |
| Tension Arm | `tension_arm.stl` | 50mm arm with 25T spline bore, spring anchor at tip |
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
