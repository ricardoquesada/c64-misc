# Makefile copied from Zoo Mania game

.SILENT:

IMAGE = "timer_dist.d64"
C1541 = c1541
X64 = x64

all: disk

SRC=timer.s
prg:
	cl65 -d -g -Ln timer.sym -u __EXEHDR__ -t c64 -o timer.prg -C timer.cfg ${SRC}

disk: prg
	$(C1541) -format "timer,rq" d64 timer.d64
	$(C1541) timer.d64 -write timer.prg
	$(C1541) timer.d64 -list

dist: prg
	exomizer sfx sys -o timer_exo.prg timer.prg
	$(C1541) -format "timer dist,rq" d64 $(IMAGE)
	$(C1541) $(IMAGE) -write timer_exo.prg "the race"
	$(C1541) $(IMAGE) -list
	rm -f intro.o timer.prg timer_exo.prg

test: disk
	$(X64) -moncommands timer.sym timer.d64

testdist: dist
	$(X64) -moncommands timer.sym $(IMAGE)

clean:
	rm -f *~ *.o timer.prg timer_exo.prg timer.d64 timer.sym $(IMAGE)
