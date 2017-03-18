.SILENT:

X64 = x64
all: plotter_mc

plotter_mc:
	cl65 -d -g -Ln plotter_mc.sym -u __EXEHDR__ -t c64 -o plotter_mc.prg -C c64-asm.cfg plotter_mc.s
	$(X64) -moncommands plotter_mc.sym plotter_mc.prg

clean:
	rm -f *.o *.prg *.sym

