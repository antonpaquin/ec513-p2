# all:
# 	iverilog -o riscv_core tb_RISC_V_Core.v RISC_V_Core.v control_unit.v fetch.v decode.v execute.v ALU.v mem_interface.v bsram.v memory.v regFile.v writeback.v

VC 		:= iverilog
TARGET	:= riscv_core
SRC 	:= $(wildcard ./*.v)

all: $(TARGET)

$(TARGET): $(SRC)
	$(VC) -o $@ $^

run:
	./$(TARGET)

cleant:
	rm $(TARGET)

cleanv:
	rm $(wildcard ./*.vcd)

cleanall:
	rm $(TARGET) $(wildcard ./*.vcd)
