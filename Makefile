DIR_UNICORE32	:= /home/zyxu/UniCore32
DIR_WORKING	:= $(DIR_UNICORE32)/working
DIR_GNU_UC	:= /pub/toolchain/uc32/unicore32-linux/

CROSS_UNICORE32	:= /pub/toolchain/uc32
CROSS_LIB	:= $(CROSS_UNICORE32)/unicore32-linux/lib
CROSS_COMPILE	:= $(CROSS_UNICORE32)/bin/unicore32-linux-
OBJDUMP		:= $(CROSS_COMPILE)objdump

BUSYBOX_TARBALL	:= ~/busybox-1.20.0.tar.bz2
BUSYBOX_CONFIG	:= $(DIR_UNICORE32)/initramfs/initramfs_busybox_config
BUSYBOX_BUILDLOG:= $(DIR_WORKING)/busybox-build.log

QEMU_GITREPO	:= /pub/git/qemu.git
QEMU_REPO31	:= $(USER)@192.168.200.31:/pub/git/qemu.git
QEMU_BUILDLOG	:= $(DIR_WORKING)/qemu-build.log
QEMU_TARGETS	:= unicore32-linux-user,unicore32-softmmu
QEMU_TRACELOG	:= $(DIR_WORKING)/trace.log
QEMU_PATCHES    := $(DIR_UNICORE32)/patches-qemu
PATH		:= $(CROSS_UNICORE32)/bin:$(PATH)

all:
	@echo ""
	@echo "Enjoy UniCore32!"
	@echo ""
	@echo "For ONE core: make highfive"
	@echo "     or: make clean"
	@echo "     or: make busybox"
	@echo "     or: make linux-new"
	@echo "     or: make linux-make"
	@echo "     or: make qemu-new"
	@echo "     or: make qemu-make"
	@echo ""
	@echo "Running qemu and get trace"
	@echo "     make qemu-run  (file and local mode)"
	@echo ""
#	@make mygit-help

#include Makefile.mygit
include Makefile.linux

highfive:
	@make clean
	@make busybox
	@make linux-new
	@make linux-make
	@make qemu-new
	@make qemu-make

clean:
	@rm -fr $(DIR_WORKING)

busybox:
	@echo "Remove old busybox ..."
	@test -d $(DIR_WORKING) || mkdir -p $(DIR_WORKING)
	@rm -fr $(DIR_WORKING)/busybox*
	@cd $(DIR_WORKING);					\
		tar xfj $(BUSYBOX_TARBALL);			\
		ln -sf busybox-1.20.0 busybox
	@echo "Configure and make busybox ..."
	@cp $(BUSYBOX_CONFIG) $(DIR_WORKING)/busybox/.config
	@yes "" | make -C $(DIR_WORKING)/busybox oldconfig	\
		>> $(BUSYBOX_BUILDLOG) 2>&1
	@make -C $(DIR_WORKING)/busybox -j4			\
		>> $(BUSYBOX_BUILDLOG) 2>&1
	@make -C $(DIR_WORKING)/busybox install			\
		>> $(BUSYBOX_BUILDLOG) 2>&1

qemu-new:
	@test -d $(DIR_WORKING)/qemu-unicore32 ||		\
		mkdir -p $(DIR_WORKING)/qemu-unicore32
	@echo "Remove old qemu repo ..."
	@rm -fr $(DIR_WORKING)/qemu
	@cd $(DIR_WORKING); git clone $(QEMU_GITREPO)
	@cd $(DIR_WORKING)/qemu;				\
		git branch unicore32 1dc33ed;				\
		git checkout unicore32;	\
        # git am $(QEMU_PATCHES)/*

qemu-make:
	@echo "Configure qemu ..."
	@cd $(DIR_WORKING)/qemu; ./configure                    \
                --target-list=$(QEMU_TARGETS)				\
                --enable-debug								\
				--disable-werror							\
				--enable-curses								\
				--extra-cflags="-D restrict=restricT"		\
				--disable-sdl                               \
       		    --interp-prefix=$(DIR_GNU_UC)               \
				--prefix=$(DIR_WORKING)/qemu-unicore32		\
				>> $(QEMU_BUILDLOG) 2>&1
	@echo "Make qemu and make install ..."
	@make -C $(DIR_WORKING)/qemu -j4 >> $(QEMU_BUILDLOG) 2>&1
	@make -C $(DIR_WORKING)/qemu install >> $(QEMU_BUILDLOG) 2>&1

qemu-run:
	@echo "Remove old log file"
	@rm -fr $(QEMU_TRACELOG)
	@echo "Running QEMU in this tty ..."
	@$(DIR_WORKING)/qemu-unicore32/bin/qemu-system-unicore32\
		-curses						\
		-M puv3						\
		-m 512						\
		-icount 0					\
		-kernel $(DIR_WORKING)/zImage
		# -net nic					\
		# -net tap,ifname=tap_$(USER),script=no,downscript=no	\
		# -append "root=/dev/nfs nfsroot=192.168.200.161:/export/guestroot/,tcp rw ip=192.168.122.4"    \
		2> $(QEMU_TRACELOG)

