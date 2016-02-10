# Makefile copied from Zoo Mania game

.SILENT:

X64 = x64
all: timer vic_detect blank_screen

timer:
	cl65 -d -g -Ln timer.sym -u __EXEHDR__ -t c64 -o timer.prg -C timer.cfg timer.s
	$(X64) -moncommands timer.sym timer.prg

vic_detect:
	cl65 -d -g -Ln vic_detect.sym -u __EXEHDR__ -t c64 -o vic_detect.prg -C c64-asm.cfg vic_detect.s
	$(X64) -moncommands vic_detect.sym vic_detect.prg

blank_screen:
	cl65 -d -g -Ln blank_screen.sym -u __EXEHDR__ -t c64 -o blank_screen.prg -C c64-asm.cfg blank_screen.s
	$(X64) -moncommands blank_screen.sym blank_screen.prg

fadeout:
	cl65 -d -g -Ln fadeout.sym -u __EXEHDR__ -t c64 -o fadeout.prg -C c64-asm.cfg fadeout.s
	$(X64) -moncommands fadeout.sym fadeout.prg

clean:
	rm -f *.o *.prg *.sym

