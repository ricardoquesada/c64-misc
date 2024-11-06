# Compile basic program

.SILENT:

X128 = x128
all: bas

bas:
	petcat -w70 -o colors.prg -- colors.bas
	$(X128) colors.prg

clean:
	rm -f *.prg

