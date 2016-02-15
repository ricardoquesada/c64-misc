.SILENT:

.PHONY: all clean build

X64 = x64

all: bitmap-1x2-scroller bitmap-diagonal-1x2-scroller sprite-1x2-scroller 8x16-scroller 8x8-scroller 8x8-double-scroller 1x1-scroller 1x2-scroller 2x1-scroller 2x2-scroller 2x2-scroller-multi 2x2-scroller-multi-with-rasterbars

bitmap-1x2-scroller: bitmap-1x2-scroller.s
	cl65 -o $@.prg -u __EXEHDR__ -t c64 -C c64-asm.cfg $^
	$(X64) -moncommands $@.sym $@.prg

bitmap-diagonal-1x2-scroller: bitmap-diagonal-1x2-scroller.s
	cl65 -o $@.prg -u __EXEHDR__ -t c64 -C c64-asm.cfg $^
	$(X64) -moncommands $@.sym $@.prg

sprite-1x2-scroller: sprite-1x2-scroller.s
	cl65 -o $@.prg -u __EXEHDR__ -t c64 -C c64-asm.cfg $^
	$(X64) -moncommands $@.sym $@.prg

8x16-scroller: 8x16-scroller.s
	cl65 -o $@.prg -u __EXEHDR__ -t c64 -C c64-asm.cfg $^
	$(X64) -moncommands $@.sym $@.prg

8x8-scroller: 8x8-scroller.s
	cl65 -o $@.prg -u __EXEHDR__ -t c64 -C c64-asm.cfg $^
	$(X64) -moncommands $@.sym $@.prg

8x8-double-scroller: 8x8-double-scroller.s
	cl65 -o $@.prg -u __EXEHDR__ -t c64 -C c64-asm.cfg $^
	$(X64) -moncommands $@.sym $@.prg

1x1-scroller: 1x1-scroller.s
	cl65 -o $@.prg -u __EXEHDR__ -t c64 -C c64-asm.cfg $^
	$(X64) -moncommands $@.sym $@.prg

2x1-scroller: 2x1-scroller.s
	cl65 -o $@.prg -u __EXEHDR__ -t c64 -C c64-asm.cfg $^
	$(X64) -moncommands $@.sym $@.prg

1x2-scroller: 1x2-scroller.s
	cl65 -o $@.prg -u __EXEHDR__ -t c64 -C c64-asm.cfg $^
	$(X64) -moncommands $@.sym $@.prg

2x2-scroller: 2x2-scroller.s
	cl65 -o $@.prg -u __EXEHDR__ -t c64 -C c64-asm.cfg $^
	$(X64) -moncommands $@.sym $@.prg

2x2-scroller-multi: 2x2-scroller-multi.s
	cl65 -o $@.prg -u __EXEHDR__ -t c64 -C c64-asm.cfg $^
	$(X64) -moncommands $@.sym $@.prg

2x2-scroller-multi-with-rasterbars: 2x2-scroller-multi-with-rasterbars.s
	cl65 -o $@.prg -u __EXEHDR__ -t c64 -C c64-asm.cfg $^
	$(X64) -moncommands $@.sym $@.prg

clean:
	rm -f *.o *.prg *.sym
