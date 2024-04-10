CC= sdcc
ASM = sdas8051
SDAR ?= sdar rc
OBJCOPY = objcopy
PACKIHX = packihx

FLASHER = sinowealth-kb-tool write -p redragon-k631

SRCDIR = src
OBJDIR = obj
BINDIR = bin

FAMILY = mcs51
PROC = mcs51

FREQ_SYS ?= 24000000
XRAM_SIZE ?= 0x1000
XRAM_LOC ?= 0x0000
CODE_SIZE ?= 0xf000 # 61440 bytes (leaving the remaining 4096 for bootloader)

SMK_VERSION ?= alpha

# Упрощение процесса резервного копирования и восстановления путем сохранения того же VID и PID, что и nuphy-air60
USB_VID ?= 0x258A
USB_PID ?= 0x0049


CFLAGS := -V -mmcs51 --model-small \
	--xram-size $(XRAM_SIZE) --xram-loc $(XRAM_LOC) \
	--code-size $(CODE_SIZE) \
	--std-c2x \
	-I$(ROOT_DIR)../include \
	-DDEBUG=1 \
	-DFREQ_SYS=$(FREQ_SYS) \
	-DWATCHDOG_ENABLE=1 \
	-DUSB_VID=$(USB_VID) \
	-DUSB_PID=$(USB_PID) \
	-DSMK_VERSION=$(SMK_VERSION)
LFLAGS := $(CFLAGS)

AFLAGS= -plosgff

SOURCES := $(SRCDIR)/main.c $(filter-out $(SRCDIR)/main.c, $(wildcard $(SRCDIR)/*.c)) # main.c has to be the first file
OBJECTS := $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.rel)

.PHONY: all clean flash

all: $(BINDIR)/main.hex

clean:
	rm -rf $(BINDIR) $(OBJDIR)

flash: $(BINDIR)/main.hex
	$(FLASHER) $(BINDIR)/main.hex

$(OBJDIR)/%.rel: $(SRCDIR)/%.c
	@mkdir -p $(@D)
	$(CC) -m$(FAMILY) -l$(PROC) $(CFLAGS) -c $< -o $@

$(BINDIR)/main.lib: $(LIB_OBJECTS)
	@mkdir -p $(@D)
	$(SDAR) $@ $^

$(BINDIR)/main.ihx: $(MAIN_OBJECTS) $(BINDIR)/main.lib
	@mkdir -p $(@D)
	$(CC) -m$(FAMILY) -l$(PROC) $(LFLAGS) -o $@ $^

$(BINDIR)/%.hex: $(BINDIR)/%.ihx
	${PACKIHX} < $< > $@

$(BINDIR)/%.bin: $(BINDIR)/%.ihx
	$(OBJCOPY) -I ihex -O binary $< $@
