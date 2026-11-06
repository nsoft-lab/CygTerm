# Makefile for CygTerm

BINDIR = $(HOME)/bin

CC = gcc
CFLAGS = -O2 -fno-exceptions -D_GNU_SOURCE
LIBS = -mwindows

EXE = cygterm.exe
SRC = $(EXE:.exe=.cc)
CFG = $(EXE:.exe=.cfg)

$(EXE) : $(SRC) $(RES)
  ifeq (0, $(shell nm /usr/lib/crt0.o | grep -c WinMainCRTStartup))
	$(CC) $(CFLAGS) -DNO_WIN_MAIN -o $(EXE) $(SRC) $(RES) $(LIBS)
  else
	$(CC) $(CFLAGS) -o $(EXE) $(SRC) $(RES) $(LIBS)
  endif
	strip $(EXE)

# icon test
#TEST_ICO = /Cygwin.ico
TEST_ICO = /Cygwin-Terminal.ico
with-icon :
	@echo "(Use $(TEST_ICO))"
	@cp $(TEST_ICO) x.ico
	@echo 'icon ICON x.ico' > x.rc
	windres -O coff -o x.res x.rc
	@rm -f x.rc x.ico
	@make RES=x.res
	@rm -f x.res

clean :
	rm -f $(EXE)

install : $(EXE)
	@ install -v $(EXE) $(BINDIR)/$(EXE)
	@ if [ ! -f $(BINDIR)/$(CFG) ]; then \
	    install -v $(CFG) $(BINDIR)/$(CFG) \
	; fi

uninstall :
	rm -f $(BINDIR)/$(EXE)
	rm -f $(BINDIR)/$(CFG)

