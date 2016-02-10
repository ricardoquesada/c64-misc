.SILENT:

X64 = x64
all: plasma_d800

plasma_d800:
	cl65 -d -g -Ln plasma_d800.sym -u __EXEHDR__ -t c64 -o plasma_d800.prg -C c64-asm.cfg plasma_d800.s
	$(X64) -moncommands plasma_d800.sym plasma_d800.prg

clean:
	rm -f *.o *.prg *.sym

