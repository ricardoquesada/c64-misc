# Makefile copied from Zoo Mania game

.SILENT:

X64 = x64
all: fli koala

fli:
	cl65 -d -g -Ln fli.sym -u __EXEHDR__ -t c64 -o fli.prg -C fli.cfg fli.s
	$(X64) -moncommands fli.sym fli.prg

koala:
	cl65 -d -g -Ln koala.sym -u __EXEHDR__ -t c64 -o koala.prg -C koala.cfg koala.s
	$(X64) -moncommands koala.sym koala.prg

clean:
	rm -f *~ *.o *.prg *.sym
