SRC = counter.v counter_tb.v
PGM = counter_sim
CC = iverilog
SIM = vvp

all:
	$(CC) -o $(PGM) $(SRC)

sim:
	$(SIM) $(PGM)

clean:
	rm -f a.out *.vcd $(PGM)
