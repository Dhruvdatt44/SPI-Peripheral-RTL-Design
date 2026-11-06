# SPI-Peripheral-RTL-Design
A complete SPI master peripheral written from scratch in Verilog, with an APB interface so any APB-based processor or bus can drive it.

 I built this one block at a time and tested every block before moving on. That's why the repo is laid out the way it is: each module does one small job, and each has its own testbench.

Status: works in simulation in all 4 SPI modes (word-level loopback and a separate slave model). Bring-up on a Spartan-7 board (Arty S7-50) is next. I'll update this section once it has run on hardware.

What it does
Acts as an SPI master talking to one slave
Supports all four SPI modes (CPOL / CPHA = 00, 01, 10, 11)
8-bit words, MSB first (word length is a parameter)
Programmable SCLK speed from a 16-bit divider
Talks to a host over an APB bus (active-high reset, no wait states)
Raises an interrupt when a transfer finishes
Synchronises the incoming MISO line with two flip-flops, so a signal from outside the chip doesn't cause metastability
