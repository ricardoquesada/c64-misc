# Makefile copied from Zoo Mania game

.SILENT:

IMAGE = "fli_dist.d64"
C1541 = /Applications/Vice/tools/c1541
X64 = /Applications/Vice/x64.app/Contents/MacOS/x64

all: disk

SRC=fli.s
prg:
	cl65 -d -g -Ln fli.sym -u __EXEHDR__ -t c64 -o fli.prg -C fli.cfg ${SRC}

disk: prg
	$(C1541) -format "fli,rq" d64 fli.d64
	$(C1541) fli.d64 -write fli.prg
	$(C1541) fli.d64 -list

dist: prg
	exomizer sfx sys -o fli_exo.prg fli.prg
	$(C1541) -format "fli dist,rq" d64 $(IMAGE)
	$(C1541) $(IMAGE) -write fli_exo.prg "the race"
	$(C1541) $(IMAGE) -list
	rm -f intro.o fli.prg fli_exo.prg

test: disk
	$(X64) -moncommands fli.sym fli.d64

testdist: dist
	$(X64) -moncommands fli.sym $(IMAGE)

clean:
	rm -f *~ *.o fli.prg fli_exo.prg fli.d64 fli.sym $(IMAGE)
