DIR_UNICORE64	:= $(wildcard ~/UniCore64)
DIR_WORKING	:= $(DIR_UNICORE64)/working
DIR_GNU_UC	:= /pub/toolchain/uc64/unicore64-linux/

CROSS_UNICORE64	:= /pub/toolchain/uc64
CROSS_LIB	:= $(CROSS_UNICORE64)/unicore64-linux/lib
CROSS_COMPILE	:= $(CROSS_UNICORE64)/bin/unicore64-linux-
OBJDUMP		:= $(CROSS_COMPILE)objdump

BUSYBOX_TARBALL	:= /pub/backup/busybox-1.21.1.tar.bz2
BUSYBOX_CONFIG	:= $(DIR_UNICORE64)/initramfs/initramfs_busybox_config
BUSYBOX_BUILDLOG:= $(DIR_WORKING)/busybox-build.log

QEMU_GITREPO	:= /pub/git/qemu.git
QEMU_BUILDLOG	:= $(DIR_WORKING)/qemu-build.log
QEMU_TARGETS	:= unicore64-linux-user,unicore64-softmmu
QEMU_TRACELOG	:= $(DIR_WORKING)/trace.log

LINUX_GITREPO	:= /pub/git/linux-unicore.git
LINUX_ARCH	:= unicore64
LINUX_BUILDLOG	:= $(DIR_WORKING)/linux-build.log

PATH		:= $(CROSS_UNICORE64)/bin:$(PATH)

ifndef SMP
	LINUX_DEFCONFIG := unicore64_defconfig
	QEMU_SMP	:= 1
else
	LINUX_DEFCONFIG := unicore64_smp_defconfig
	QEMU_SMP	:= 2
endif

all:
	@echo ""
	@echo "Enjoy UniCore64!"
	@echo ""
	@echo "For ONE core: make highfive"
	@echo "     or: make clean"
	@echo "     or: make busybox"
	@echo "     or: make linux-new"
	@echo "     or: make linux-make"
	@echo "     or: make qemu-new"
	@echo "     or: make qemu-make"
	@echo ""
	@echo "For SMP: SMP=y make highfive"
	@echo "     or: make clean"
	@echo "     or: make busybox"
	@echo "     or: make linux-new"
	@echo "     or: SMP=y make linux-make"
	@echo "     or: make qemu-new"
	@echo "     or: make qemu-make"
	@echo ""
	@echo "Running qemu and get trace"
	@echo "     make qemu-run  (file and local mode)"
	@echo "     or: SMP=y make qemu-run  (file and local mode)"
	@echo ""

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
		ln -sf busybox-1.21.1 busybox
	@echo "Configure and make busybox ..."
	@cp $(BUSYBOX_CONFIG) $(DIR_WORKING)/busybox/.config
	@yes "" | make -C $(DIR_WORKING)/busybox oldconfig	\
		>> $(BUSYBOX_BUILDLOG) 2>&1
	@make -C $(DIR_WORKING)/busybox -j4			\
		>> $(BUSYBOX_BUILDLOG) 2>&1
	@make -C $(DIR_WORKING)/busybox install			\
		>> $(BUSYBOX_BUILDLOG) 2>&1

linux-new:
	@echo "Remove old linux repo ..."
	@test -d $(DIR_WORKING) || mkdir -p $(DIR_WORKING)
	@rm -fr $(DIR_WORKING)/linux
	@echo "Clone and checkout unicore64 branch"
	@cd $(DIR_WORKING);					\
		git clone $(LINUX_GITREPO) -- linux
	@cd $(DIR_WORKING)/linux;				\
		git checkout -b unicore64 origin/unicore64

linux-make:
	@echo "Make mrproper ..."
	@make -C $(DIR_WORKING)/linux ARCH=$(LINUX_ARCH)	\
		mrproper >> $(LINUX_BUILDLOG) 2>&1
	@echo "Make $(LINUX_DEFCONFIG) ..."
	@make -C $(DIR_WORKING)/linux ARCH=$(LINUX_ARCH)	\
		$(LINUX_DEFCONFIG) >> $(LINUX_BUILDLOG) 2>&1
	@echo "Making (in several minutes) ..."
	@make -C $(DIR_WORKING)/linux ARCH=$(LINUX_ARCH) -j4	\
		>> $(LINUX_BUILDLOG) 2>&1
	@echo "Softlinking necessary files ..."
	@ln -sf $(DIR_WORKING)/linux/arch/unicore64/boot/zImage $(DIR_WORKING)
	@ln -sf $(DIR_WORKING)/linux/System.map $(DIR_WORKING)
	@echo "Generating disassembly file for vmlinux ..."
	@$(OBJDUMP) -D $(DIR_WORKING)/linux/vmlinux		\
		> $(DIR_WORKING)/vmlinux.disasm

qemu-new:
	@test -d $(DIR_WORKING)/qemu-unicore64 ||		\
		mkdir -p $(DIR_WORKING)/qemu-unicore64
	@echo "Remove old qemu repo ..."
	@rm -fr $(DIR_WORKING)/qemu
	@cd $(DIR_WORKING); git clone $(QEMU_GITREPO)
	@cd $(DIR_WORKING)/qemu;				\
		git br unicore64 origin/unicore64;		\
		git co unicore64

qemu-make:
	@echo "Configure qemu ..."
	@cd $(DIR_WORKING)/qemu; ./configure			\
		--enable-trace-backend=stderr			\
		--target-list=$(QEMU_TARGETS)			\
		--enable-debug			 		\
		--disable-sdl			 		\
		--interp-prefix=$(DIR_GNU_UC)			\
		--prefix=$(DIR_WORKING)/qemu-unicore64		\
		>> $(QEMU_BUILDLOG) 2>&1
	@echo "Make qemu and make install ..."
	@make -C $(DIR_WORKING)/qemu -j4 >> $(QEMU_BUILDLOG) 2>&1
	@make -C $(DIR_WORKING)/qemu install >> $(QEMU_BUILDLOG) 2>&1

qemu-run:
	@echo "Remove old log file"
	@rm -fr $(QEMU_TRACELOG)
	@echo "Running QEMU in this tty ..."
	@$(DIR_WORKING)/qemu-unicore64/bin/qemu-system-unicore64\
		-curses						\
		-M puv4						\
		-m 512						\
		-smp $(QEMU_SMP)				\
		-icount 0					\
		-kernel $(DIR_WORKING)/zImage			\
		-append "root=/dev/ram"				\
		2> $(QEMU_TRACELOG)

