SRC = hello.v
PGM = hello
CC = iverilog
SIM = vvp

all:
	$(CC) -o $(PGM) $(SRC)

sim:
	@$(SIM) $(PGM)

clean:
	rm -f a.out *.vcd $(PGM)
