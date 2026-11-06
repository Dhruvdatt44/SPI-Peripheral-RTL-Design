# SPI-Peripheral-RTL-Design (Verilog)

A complete SPI **master** peripheral written from scratch in Verilog, with an APB interface so any APB-based processor or bus can drive it.

I built it one block at a time and tested every block before moving on. That's why the repo is laid out the way it is: each module does one small job, and each has its own testbench.

> **Status:** works in simulation in all 4 SPI modes (word-level loopback and a separate slave model). Bring-up on a Spartan-7 board (Arty S7-50) is next. I'll update this section once it has run on hardware.

---

## What it does

- Acts as an SPI **master** talking to one slave
- Supports all four SPI modes (CPOL / CPHA = 00, 01, 10, 11)
- 8-bit words, MSB first (word length is a parameter)
- Programmable SCLK speed from a 16-bit divider
- Talks to a host over an **APB** bus (active-high reset, no wait states)
- Raises an **interrupt** when a transfer finishes
- Synchronises the incoming MISO line with two flip-flops, so a signal from outside the chip doesn't cause metastability

**Not included (yet):** multiple chip selects, TX/RX FIFOs, DMA.

---

## How it fits together

The design has three main blocks, wired together by `spi_top`:

1. **Register file** (`spi_register_file`) – the APB side. It holds the control, status, divider, transmit and receive registers and produces the interrupt.
2. **SPI engine** (`spi_engine_top`) – does the actual transfer. It is made of four small modules:
   - `SPI_FSM` decides what happens when: chip select, load, enable.
   - `spi_clkdiv` slows the system clock down to SCLK speed.
   - `SPI_edge_gen` produces SCLK and the "sample" and "shift" pulses for the chosen mode.
   - `shiftregisters` turns a byte into bits on MOSI and collects the bits from MISO back into a byte.
3. **Pin interface** (`spi_pin_interface`) – connects the engine to the pads and synchronises MISO on the way in.

`spi_top` is the module you instantiate in your design.

Everything runs on the single APB clock (`Pclk`). SCLK is made by a clock enable, not a separate divided clock, which keeps timing simple.

---

## Pins

| Signal | Dir | Width | Meaning |
|---|---|---|---|
| `Pclk` | in | 1 | APB / system clock |
| `Preset` | in | 1 | Reset, **active high** |
| `Psel` `Penable` `Pwrite` | in | 1 each | APB control |
| `Paddr` | in | 8 | Register address (bits [4:2] are decoded) |
| `Pwdata` / `Prdata` | in / out | 32 | APB data |
| `Pready` | out | 1 | Always 1 (no wait states) |
| `Irq` | out | 1 | Interrupt to the host |
| `SCLK` `MOSI` `CS` | out | 1 each | SPI to the slave (`CS` is active low) |
| `MISO` | in | 1 | SPI from the slave |

---

## Register map

| Offset | Name | Access | Bits |
|---|---|---|---|
| `0x00` | CTRL | R/W | `[1]` CPOL, `[2]` CPHA, `[3]` IRQ_EN |
| `0x04` | STATUS | R | `[0]` BUSY, `[1]` DONE |
| `0x08` | CLKDIV | R/W | `[15:0]` divider |
| `0x0C` | TXDATA | R/W | `[7:0]` byte to send. **Writing it starts a transfer** (if not busy) |
| `0x10` | RXDATA | R | `[7:0]` last received byte. **Reading it clears DONE and the IRQ** |

**SCLK frequency** is the APB clock divided by 2 × (CLKDIV + 1). For example, a 100 MHz clock with CLKDIV = 49 gives a 1 MHz SCLK.

**Typical use:** write CTRL and CLKDIV once, then write a byte to TXDATA. Wait for DONE in STATUS (or for the interrupt), then read RXDATA, which also clears DONE and the interrupt.

To use the interrupt instead of polling, set bit 3 of CTRL. `Irq` stays high from the end of the transfer until RXDATA is read.

---

## How a transfer works

The FSM walks through five states:

1. **IDLE** – CS high, everything quiet.
2. **CS_SETUP** – CS goes low and the byte is loaded. A couple of clocks pass before SCLK moves, because slaves need setup time.
3. **SHIFT** – the clock divider runs and eight SCLK periods go out. MOSI changes on one edge, MISO is sampled on the other. Which is which depends on the mode.
4. **CS_HOLD** – SCLK has stopped, CS stays low for a few more clocks so the slave sees the last edge before CS rises.
5. **DONE** – CS goes high, a one-cycle `done` pulse is produced, and the register file latches it.

**The four modes**

| Mode | CPOL | CPHA | SCLK idles | Data sampled on |
|---|---|---|---|---|
| 0 | 0 | 0 | low | rising edge |
| 1 | 0 | 1 | low | falling edge |
| 2 | 1 | 0 | high | falling edge |
| 3 | 1 | 1 | high | rising edge |

One detail that took a while to get right: with CPHA=0 the first bit has to be on MOSI *before* the first clock edge, but with CPHA=1 it appears *on* the first edge. The shift register treats those two cases differently when the byte is loaded.

---

## Files

| File | What it is |
|---|---|
| `spi_top.v` | Top level: register file + engine + pin interface |
| `spi_register_file.v` | APB registers, interrupt logic |
| `spi_engine_top.v` | Engine: FSM, clock divider, edge generator, shift registers |
| `spi_fsm.v` | Transfer control (`SPI_FSM`) |
| `spi_clkdiv.v` | Programmable clock-enable divider |
| `spi_edge_gen.v` | SCLK and sample/shift pulse generator (`SPI_edge_gen`) |
| `shiftregisters.v` | TX and RX shift registers |
| `spi_pin_interface.v` | Pad connections and the MISO synchroniser |

Testbenches live in `tb/`:

| File | What it checks |
|---|---|
| `tb_spi_top_all_modes.v` | Whole peripheral through APB, loopback, 4 modes × 3 words |
| `tb_spi_full.v` | Whole peripheral with a mode-aware slave model that sends its *own* byte, so MOSI and MISO are checked separately; also checks STATUS, IRQ and the busy-write rule |
| `tb_spi_engine_all_modes.v` | Engine only, loopback, 4 modes |
| `tb_spi_register_file_v2.v` | Register file: read/write, start pulse, IRQ latch |
| `tb_spi_pin_interface.v` | MISO synchroniser |
| `tb_spi_clkdiv.v`, `tb_shiftregisters.v`, `tb_edge_gen.v`, `tb_spi_fsm_state.v` | The small building blocks |

---

## Running the simulation

**Vivado**

1. Add the `.v` files as design sources and the `tb_*.v` files as simulation sources.
2. Right-click the testbench you want and choose **Set as Top**.
3. Choose **Run Simulation → Run Behavioral Simulation**, then **Run All**.
4. The Tcl console prints a line per word and ends with `ALL ... PASSED`.

Any other Verilog simulator that supports SystemVerilog-2012 syntax, such as Icarus Verilog, works too: compile one testbench together with the design files and run it.

---

## Trying it on an FPGA

The plan for the first hardware test is a **loopback**: jumper MOSI to MISO on a Pmod header, send a byte, and check that the same byte comes back. A tiny APB test block does the same register writes that software would. Details are in the board-specific top (Arty S7-50, XC7S50-CSGA324). Use 3.3 V only.

---

## Lessons learned

A few bugs that cost real time, in case they save you some:

- **CPHA=1 dropped the first bit.** Preloading MOSI at load time is right for CPHA=0 and wrong for CPHA=1.
- **CS rose with no margin after the last clock edge.** The slave needs hold time, hence `CS_HOLD`.
- **One register driven from two `always` blocks.** The simulator accepts it, the synthesiser doesn't. Give each reg exactly one driver.
- **Testbench races.** Sample outputs a moment *after* the clock edge, not on it.
- **Missing reset on a config register** (`irq_en_reg`) leaves it unknown at power-up.

---

## Roadmap

- [x] Clock divider, shift registers, edge generator, FSM
- [x] Engine integration, all four modes
- [x] APB register file with interrupt
- [x] Pin interface with MISO synchroniser
- [x] Full-peripheral testbenches
- [ ] Run on real hardware (Arty S7-50)
- [ ] TX/RX FIFOs
- [ ] Test it from software on a processor

---

## License

Choose a license and put its name here (MIT is a common default for hobby projects).
