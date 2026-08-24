# 1-Wire Hardware Peripheral — Cyclone II / Nios II

Hardware state-machine implementation of the 1-Wire bus protocol, built as
a memory-mapped peripheral for a Nios II soft core on an EP2C5T144 Cyclone
II board. Companion to a software (bit-banged) 1-Wire driver on an
AT89S52 -- same protocol, deliberately different implementation mechanism.

## Layout

```
onewire_project/
  src/
    onewire_reset.v       Stage 1: RESET / PRESENCE detect FSM
  sim/
    onewire_reset_tb.v    Testbench w/ fake slave, verifies stage 1
  quartus/
    (empty -- .qpf/.qsf/Qsys system go here once wired to Nios II)
```

## Build Order (matches the design discussion this came out of)

1. **RESET / PRESENCE FSM** -- `src/onewire_reset.v` -- DONE, simulated passing
2. **WRITE_BIT / WRITE_BYTE** -- next file to add
3. **READ_BIT / READ_BYTE** -- reuses the write-bit bit-loop structure
4. **Avalon-MM wrapper** -- exposes CMD/CTRL/STATUS/DATA registers to Qsys
5. **Wire into a Nios II Qsys system**, confirm register access from C

Each stage should be simulated and passing before moving to the next --
don't wire anything to real hardware pins until the testbench confirms it.

## Running the Testbench

Requires Icarus Verilog (`iverilog`/`vvp`) or ModelSim-Altera (bundled
with Quartus II 13.0sp1).

```bash
cd sim
iverilog -o sim.out onewire_reset_tb.v ../src/onewire_reset.v
vvp sim.out
```

Expect:
```
PASS: presence detected at time <...>
```

To view waveforms (Icarus writes `onewire_reset_tb.vcd`):
```bash
gtkwave onewire_reset_tb.vcd
```

## Notes on the Testbench

- Runs the DUT at `CLK_HZ = 1_000_000` (not the real board's 50MHz) purely
  so the 480us+ reset timing simulates in a manageable number of cycles.
  The FSM's internal cycle-count math (`CYCLES_PER_US`) is exercised
  identically either way -- only wall-clock sim time changes. Re-run with
  `CLK_HZ = 50_000_000` once you want a fully representative timing run.
- The fake slave asserts presence 30us after release and holds it 150us --
  both comfortably inside spec (15-60us assert window, 60-240us hold) with
  margin. If you want to stress-test the FSM's sampling window, try moving
  the slave's assert delay toward the 15us or 60us edges and confirm
  presence is still detected correctly.
- A first version of this testbench had the slave assert presence 100us
  after release -- outside the 15-60us spec window -- and the DUT
  correctly reported no presence, since it had already sampled by then.
  Worth remembering: a "FAIL" from a testbench isn't always a DUT bug --
  check the testbench's own modeled timing against spec first.

## Once You're on Real Hardware

Confirm actual board clock frequency and pin mapping using the separate
`blinky_top` bring-up project before assigning `dq_in`/`dq_oe` to a real
pin here -- see that project's README/comments for the blink-rate
stopwatch method.
