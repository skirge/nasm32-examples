APP=masmlike
TEST=tester
DLLS=user32.dll kernel32.dll
RES=

APP_SRC= $(APP).asm
TEST_SRC= $(TEST).asm
APP_OBJ= $(patsubst %.asm,%.obj,$(APP_SRC))
TEST_OBJ= $(patsubst %.asm,%.obj,$(TEST_SRC) $(APP_SRC))

NASM=nasm
LINK=golink
RC=gorc
BUILDDIR=Build

NASMFLAGS=-f win32
LINKFLAGS= /entry _START
RCFLAGS=

VPATH=$(BUILDDIR)

.PHONY:	all run test clean $(BUILDDIR)

all: $(BUILDDIR) $(APP).exe 

%.obj: %.asm
		$(NASM) $(NASMFLAGS) -o $(BUILDDIR)/$@ $^

%.res: %.rc
		$(RC) $(RCFLAGS) -fo $(BUILDDIR)/$@ $^
	
$(BUILDDIR):
		-mkdir	$(BUILDDIR)

$(APP).exe: $(APP_OBJ) $(RES)
		$(LINK) $(LINKFLAGS) $(foreach ble,$^,"$(ble)") $(DLLS)

$(TEST).exe: $(TEST_OBJ) $(RES)
		$(LINK) $(LINKFLAGS) $(foreach ble,$^,"$(ble)") $(DLLS)
		        
run:    $(APP).exe
		$(BUILDDIR)/$(APP).exe
		
test:	$(TEST).exe
		$(BUILDDIR)/$(TEST).exe

clean:
		-rm -f $(BUILDDIR)/*.exe  $(BUILDDIR)/*.obj $(BUILDDIR)/*.res