# Dallas 1-Wire Module

Verilog FPGA 1-Wire master and slave controllers.

Designed as a peripheral to interface with a 8051 style soft core.

## 1-Wire Master

Registers:

<pre>
Register	Width	Purpose
OW_CMD	8-bit, write	Opcode: 0x01=RESET, 0x02=WRITE_BYTE, 0x03=READ_BYTE
OW_DATA	8-bit, read/write	Byte to send (write side) / byte received (read side) — dual-purpose, exactly like SBUF on the UART
OW_CTRL	8-bit, write	Bit 0 = START (self-clearing strobe, triggers the FSM to consume OW_CMD)
OW_STATUS	8-bit, read	Bit 0 = BUSY, Bit 1 = DONE, Bit 2 = PRESENCE (valid after a RESET completes)
</pre>

## 1-Wire Slave

## FSM

<pre>
IDLE
  │  (START strobe, OW_CMD = RESET)
  ▼
OW_RESET_LOW      — drive pin low, count cycles for 480us
  │
  ▼
OW_RESET_RELEASE  — release (tri-state), count cycles into sample window (~70us)
  │
  ▼
OW_SAMPLE_PRESENCE — sample pin, latch into STATUS.PRESENCE
  │
  ▼
OW_RESET_RECOVER  — count remaining cycles to complete the 480us+ minimum slot
  │
  ▼
IDLE (STATUS.DONE = 1, STATUS.BUSY = 0)
</pre>

## Example Usage

```c
// Issue a reset
OW_CMD = 0x01;
OW_CTRL = 0x01;          // START
while (OW_STATUS & 0x01);  // poll BUSY, same idiom as while(!TF0)
bit presence = OW_STATUS & 0x04;

// Write a byte
OW_DATA = 0xCC;
OW_CMD = 0x02;
OW_CTRL = 0x01;
while (OW_STATUS & 0x01);

// Read a byte
OW_CMD = 0x03;
OW_CTRL = 0x01;
while (OW_STATUS & 0x01);
unsigned char result = OW_DATA;
```

## References

* [1 Wire (Wikipedia)](https://en.wikipedia.org/wiki/1-Wire)
* [DS18B20 Temperature Sensor](https://www.analog.com/en/products/ds18b20.html)
