
## 准备Linux内核

1. 创建
	在tag=v3.7 base=29594404d7fe73cd80eaa4ee8c43dcc53970c60e上创建工作目录

2. 打patch
	用patches-linux-unhandled 通过git am打patch

3. 编译
	make linux-make

## 准备QEMU

1. 创建
	在base=0b8db8f上创建工作目录

2. 打patch
	用UniCore64提供的patches
	并加上UC64B组胡越予同学提供的两个patches(解决了qemu-options某个table list为空和GCC5的问题)

3. 编译
	修改Makefile
		qemu configure参数添加以下（用来解决qemu时的错误和运行curses的错误）
		--disable-werror                                \
	    --enable-curses                                 \
	    --extra-cflags="-D restrict=restricT"           \
	make qemu-make

## 准备Initramfs

1. 准备busybox
	设置正确的busybox源码包位置
	make busybox

2. 添加helloworld程序
	修改initramfs目录下的initramfs_config.busybox
	添加helloworld程序在etc目录
	并设置相应的映射

3. 编译部署
	修改Makefile.linux
	使用linux/arch/unicore32/configs/qemu_defconfig作为defconfig文件
	重新编译linux内核


## 运行QEMU

1. 修改运行参数
	修改qemu-run 去掉net相关设置

2. 运行
	make qemu-run



针对这个问题 今天思考的流程

1. 是Patch的问题吗？
	如何正确的打patch
	patch-linux 和 patch-linux-unhandled 对应的是不同的Kernel版本
	通过对应正确的版本解决Patch版本的问题
2. 是initramfs的问题吗？
	是否可能是没有正确的设置initramfs导致kernel无法启动
3. 是



/home/UC32B/LL1400012978/initramfs/initramfs_config.busybox


## Reset Vector
	CPU上电后 first instruction的地址
	hard-coded的
	体系相关的


## 32位程序无法在64位机器上运行
	及解决方法

32位程序无法在64位机器上直接运行
	*这里指x86_64和x86(i386)

解决方法
	

还有其他可能的问题
	库文件需要32位的


## GDB查看core dump文件

1. 产生core dump文件的要求
	要有core文件
	ulimit -c unlimited
2. 要有产生core dump文件的程序的ELF文件
3. GDB elf core
4. 用where查看产生core dump的stack

## Create and apply patch

## Busybox


## 如何远程GDB
