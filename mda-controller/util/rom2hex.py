#!/usr/bin/env python 

with open("BIOS.F08", "rb") as f, open("font.hex", "w") as out:
    for byte in f.read():
        out.write(f"{byte:02X}\n")
