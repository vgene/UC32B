DIR_UNICORE32	:= $(wildcard ~/UniCore32)
DIR_WORKING	:= $(DIR_UNICORE32)/working
DIR_GNU_UC	:= /pub/toolchain/uc32/unicore32-linux/

CROSS_UNICORE32	:= /pub/toolchain/uc32
CROSS_LIB	:= $(CROSS_UNICORE32)/unicore32-linux/lib
CROSS_COMPILE	:= $(CROSS_UNICORE32)/bin/unicore32-linux-
OBJDUMP		:= $(CROSS_COMPILE)objdump

BUSYBOX_TARBALL	:= /pub/backup/busybox-1.20.0.tar.bz2
BUSYBOX_CONFIG	:= $(DIR_UNICORE32)/initramfs/initramfs_busybox_config
BUSYBOX_BUILDLOG:= $(DIR_WORKING)/busybox-build.log

QEMU_GITREPO	:= /pub/git/qemu.git
QEMU_BUILDLOG	:= $(DIR_WORKING)/qemu-build.log
QEMU_TARGETS	:= unicore32-linux-user,unicore32-softmmu
QEMU_TRACELOG	:= $(DIR_WORKING)/trace.log

LINUX_LOCALREPO	:= /pub/git/linux.git
LINUX_REMOTEREPO:= $(USER)@192.168.200.31:/pub/git/linux.git
LINUX_ARCH	:= unicore32
LINUX_BUILDLOG	:= $(DIR_WORKING)/linux-build.log

PATH		:= $(CROSS_UNICORE32)/bin:$(PATH)

LINUX_DEFCONFIG := qemu_defconfig

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
		ln -sf busybox-1.20.0 busybox
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
	@echo "Clone local repo"
	@cd $(DIR_WORKING);						\
		git clone $(LINUX_LOCALREPO) -- linux
	@echo "Add and update remote repo (passwd needed) ..."
	@cd $(DIR_WORKING)/linux;					\
		git remote add repo31 $(LINUX_REMOTEREPO);		\
		git remote update repo31
	@echo "Git branch and checkout unicore32 patches"
	@cd $(DIR_WORKING)/linux;					\
		git branch unicore32 repo31/unicore32;			\
		git branch unicore32-working repo31/unicore32-working;	\
		git checkout unicore32-working

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
	@ln -sf $(DIR_WORKING)/linux/arch/unicore32/boot/zImage $(DIR_WORKING)
	@ln -sf $(DIR_WORKING)/linux/System.map $(DIR_WORKING)
	@echo "Generating disassembly file for vmlinux ..."
	@$(OBJDUMP) -D $(DIR_WORKING)/linux/vmlinux		\
		> $(DIR_WORKING)/vmlinux.disasm

qemu-new:
	@test -d $(DIR_WORKING)/qemu-unicore32 ||		\
		mkdir -p $(DIR_WORKING)/qemu-unicore32
	@echo "Remove old qemu repo ..."
	@rm -fr $(DIR_WORKING)/qemu
	@cd $(DIR_WORKING); git clone $(QEMU_GITREPO)
	@cd $(DIR_WORKING)/qemu;				\
		git br unicore32 origin/unicore32;		\
		git co unicore32

qemu-make:
	@echo "Configure qemu ..."
	@cd $(DIR_WORKING)/qemu; ./configure			\
		--enable-trace-backend=stderr			\
		--target-list=$(QEMU_TARGETS)			\
		--enable-debug			 		\
		--disable-sdl			 		\
		--interp-prefix=$(DIR_GNU_UC)			\
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
		-kernel $(DIR_WORKING)/zImage			\
		-net nic					\
		-net tap,ifname=tap_$(USER),script=no,downscript=no	\
		-append "root=/dev/nfs nfsroot=192.168.200.161:/export/guestroot/,tcp rw ip=192.168.122.4"    \
		2> $(QEMU_TRACELOG)

