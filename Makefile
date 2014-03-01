DIR_UNICORE64	:= $(wildcard ~/UniCore64)
DIR_WORKING	:= $(DIR_UNICORE64)/working
DIR_RESULTS	:= $(DIR_UNICORE64)/results
DIR_INITRD	:= $(DIR_WORKING)/initrd

CROSS_UNICORE64	:= /pub/toolchain/uc64
CROSS_LIB	:= $(CROSS_UNICORE64)/unicore64-linux/lib
CROSS_COMPILE	:= $(CROSS_UNICORE64)/bin/unicore64-linux-
OBJDUMP		:= $(CROSS_COMPILE)objdump

TEST_SAMPLE	:= $(DIR_UNICORE64)/tests/app.c

QEMU_GITREPO	:= /pub/git/qemu.git
QEMU_BUILDLOG	:= $(DIR_WORKING)/qemu-build.log
QEMU_TARGETS	:= x86_64-linux-user,x86_64-softmmu
QEMU_TRACELOG	:= $(DIR_WORKING)/trace.log

LINUX_GITREPO	:= /pub/git/linux-unicore.git
LINUX_ARCH	:= unicore64
LINUX_BUILDLOG	:= $(DIR_WORKING)/linux-build.log

INITRD_BUSYBOX	:= /pub/backup/busybox-1.21.1.tar.bz2
INITRD_BBCONFIG	:= $(DIR_UNICORE64)/initramfs/initramfs_busybox_config
INITRD_BUILDLOG	:= $(DIR_WORKING)/initrd-build.log

export PYTHONPATH = $(DIR_UNICORE64)/qxlib

all:
	@echo ""
	@echo "Enjoy UniCore64!"
	@echo ""
	@echo "Step  0:"
	@echo "     or: make clean"
	@echo "     or: make linux"
	@echo "     or: make busybox"
	@echo "     or: make qemu"
	@echo ""
	@echo "Step  2: running qemu and get trace"
	@echo "    op1: make qemu-run  (file and local mode)"
	@echo ""

highfive:
	@make clean
	@make linux
	@make initrd
	@make qxtrigger
	@make qemu

clean:
	@rm -fr $(DIR_RESULTS)
	@rm -fr $(DIR_WORKING)

linux:
	@echo "Remove old linux repo ..."
	@test -d $(DIR_WORKING) || mkdir -p $(DIR_WORKING)
	@rm -fr $(DIR_WORKING)/linux
	@echo "Clone and checkout unicore64 branch"
	@cd $(DIR_WORKING);					\
		git clone $(LINUX_GITREPO) -- linux
	@cd $(DIR_WORKING)/linux;					\
		git checkout -b unicore64 origin/unicore64
	@echo "Make defconfig ..."
	@make -C $(DIR_WORKING)/linux ARCH=$(LINUX_ARCH)	\
		defconfig >> $(LINUX_BUILDLOG) 2>&1
	@echo "Making (in several minutes) ..."
	@make -C $(DIR_WORKING)/linux ARCH=$(LINUX_ARCH) -j4	\
		>> $(LINUX_BUILDLOG) 2>&1
	@echo "Softlinking necessary files ..."
	@ln -s $(DIR_WORKING)/linux/arch/unicore64/boot/zImage $(DIR_WORKING)
	@ln -s $(DIR_WORKING)/linux/System.map $(DIR_WORKING)
	@echo "Generating disassembly file for vmlinux ..."
	@$(OBJDUMP) -D $(DIR_WORKING)/linux/vmlinux		\
		> $(DIR_WORKING)/vmlinux.disasm

busybox:
	@echo "Remove old busybox ..."
	@rm -fr $(DIR_WORKING)/busybox-*
	@cd $(DIR_WORKING); tar xfj $(INITRD_BUSYBOX); ln -sf busybox-1.21.1 busybox
	@echo "Configure and make busybox ..."
	@cp $(INITRD_BBCONFIG) $(DIR_WORKING)/busybox/.config
	@yes "" | make -C $(DIR_WORKING)/busybox oldconfig	\
		>> $(INITRD_BUILDLOG) 2>&1
	@make -C $(DIR_WORKING)/busybox -j4			\
		>> $(INITRD_BUILDLOG) 2>&1
	@make -C $(DIR_WORKING)/busybox install			\
		>> $(INITRD_BUILDLOG) 2>&1

test-sample:
	@test -d $(DIR_INITRD) || mkdir -p $(DIR_INITRD)
	@echo "Compile test app, and generate disasm and symtab files ..."
	@gcc -o $(DIR_INITRD)/app $(TEST_SAMPLE)
	@objdump -D $(DIR_INITRD)/app > $(DIR_WORKING)/app.disasm
	@objdump -t $(DIR_INITRD)/app > $(DIR_WORKING)/app.symtab

qemu:
	@test -d $(DIR_WORKING)/qemu-x86_64 ||			\
		mkdir -p $(DIR_WORKING)/qemu-x86_64
	@echo "Remove old qemu repo ..."
	@rm -fr $(DIR_WORKING)/qemu
	@cd $(DIR_WORKING); git clone $(QEMU_GITREPO)
	@cd $(DIR_WORKING)/qemu;				\
		git br qxtree v1.7.0;				\
		git co qxtree;					\
		git am $(DIR_UNICORE64)/patches-qemu/*
	@echo "Configure qemu ..."
	@cd $(DIR_WORKING)/qemu; ./configure			\
		--enable-trace-backend=stderr			\
		--target-list=$(QEMU_TARGETS)			\
		--enable-debug			 		\
		--disable-sdl			 		\
		--prefix=$(DIR_WORKING)/qemu-x86_64		\
		>> $(QEMU_BUILDLOG) 2>&1
	@echo "Make qemu and make install ..."
	@make -C $(DIR_WORKING)/qemu -j4 >> $(QEMU_BUILDLOG) 2>&1
	@make -C $(DIR_WORKING)/qemu install >> $(QEMU_BUILDLOG) 2>&1

qemu-run:
	@echo "Remove old log file"
	@rm -fr $(QEMU_TRACELOG)
	@echo "Running QEMU in this tty ..."
	@$(DIR_WORKING)/qemu-x86_64/bin/qemu-system-x86_64	\
		-nographic				        \
		-m 512					        \
		-icount 0					\
		-kernel $(DIR_WORKING)/bzImage			\
		-initrd $(INITRD_CPIO)				\
		-append "console=ttyS0 root=/dev/ram"		\
		2> $(QEMU_TRACELOG)

