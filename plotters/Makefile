.SILENT:

X64 = x64
all: plotter_bitmap_mc plotter_charset_mc plotter_charset_mc2

plotter_bitmap_mc:
	cl65 -d -g -Ln plotter_bitmap_mc.sym -u __EXEHDR__ -t c64 -o plotter_bitmap_mc.prg -C c64-asm.cfg plotter_bitmap_mc.s
	$(X64) -moncommands plotter_bitmap_mc.sym plotter_bitmap_mc.prg

plotter_charset_mc:
	cl65 -d -g -Ln plotter_charset_mc.sym -u __EXEHDR__ -t c64 -o plotter_charset_mc.prg -C plotter.cfg plotter_charset_mc.s
	$(X64) -moncommands plotter_charset_mc.sym plotter_charset_mc.prg

plotter_charset_mc2:
	cl65 -d -g -Ln plotter_charset_mc2.sym -u __EXEHDR__ -t c64 -o plotter_charset_mc2.prg -C plotter.cfg plotter_charset_mc2.s
	$(X64) -moncommands plotter_charset_mc2.sym plotter_charset_mc2.prg

clean:
	rm -f *.o *.prg *.sym

