# Makefile copied from Zoo Mania game

.SILENT:

X64 = x64
all: timer vic_detect

timer:
	cl65 -d -g -Ln timer.sym -u __EXEHDR__ -t c64 -o timer.prg -C timer.cfg timer.s
	$(X64) -moncommands timer.sym timer.prg

vic_detect:
	cl65 -d -g -Ln vic_detect.sym -u __EXEHDR__ -t c64 -o vic_detect.prg -C vic_detect.cfg vic_detect.s
	$(X64) -moncommands vic_detect.sym vic_detect.prg

clean:
	rm -f *.o *.prg *.sym

