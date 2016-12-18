# 最新修改

## QEMU

版本选择：

tag v2.7.0-rc0

branch id: 2d2e632ad00d11867c6c5625605b1fbc022dd62f 

patch: QEMU-2d2e632-0001-modify-target-unicore32.patch

# 工程架构

## 环境列表
	本地:		MacOS					~/UniCore32			备份 & 服务器与Github中转用
				VB	Ubuntu16.04 X86_64	~/UniCore32			与服务器端一致的本地运行环境
	服务器端:		Ubuntu16.04 X86_64		~/unicore32			服务器端标准运行环境
										~/UniCore32.git		裸库
	GitHub端:	https://github.com/vgene/UC32B/settings		GitHub备份

## Git关系
	Server	<-> Server Bare Repository	<->	MBP	<->	Github
										<->	VB

# 工作流程

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


#思考流程

## 各种问题

1. 是Patch的问题吗？

	如何正确的打patch
	patch-linux 和 patch-linux-unhandled 对应的是不同的Kernel版本
	通过对应正确的版本解决Patch版本的问题

2. 是initramfs的问题吗？

	是否可能是没有正确的设置initramfs导致kernel无法启动

3. 是QEMU的问题吗？



## Reset Vector
	CPU上电后 first instruction的地址
	hard-coded的
	体系相关的


## 32位程序无法在64位机器上运行
	及解决方法

32位程序无法在64位机器上直接运行
	*这里指x86_64和x86(i386)

解决方法
	安装相应的库文件

还有其他可能的问题
	库文件需要32位的


## GDB查看core dump文件

1. 产生core dump文件的要求
	要有core文件
	ulimit -c unlimited
2. 要有产生core dump文件的程序的ELF文件
3. GDB elf core
4. 用where查看产生core dump的stack

DUMP结果:
```
#0  0x00007ff94314e428 in __GI_raise (sig=sig@entry=6)
   at ../sysdeps/unix/sysv/linux/raise.c:54
#1  0x00007ff94315002a in __GI_abort () at abort.c:89
#2  0x00005556d2f2229b in cpu_abort (cpu=0x5556d5241000, 
    fmt=0x5556d3189d5b "Unhandled exception 0x%x\n")
    at /home/zyxu/UniCore32/working/qemu/exec.c:927
#3  0x00005556d2f9ba7d in uc32_cpu_do_interrupt (cs=0x5556d5241000)
    at /home/zyxu/UniCore32/working/qemu/target-unicore32/softmmu.c:106
#4  0x00005556d2f2beaa in cpu_handle_exception (cpu=0x5556d5241000, 
    ret=0x7ff93f9c9b20) at /home/zyxu/UniCore32/working/qemu/cpu-exec.c:427
#5  0x00005556d2f2c41d in cpu_exec (cpu=0x5556d5241000)
    at /home/zyxu/UniCore32/working/qemu/cpu-exec.c:617
#6  0x00005556d2f570df in tcg_cpu_exec (cpu=0x5556d5241000)
    at /home/zyxu/UniCore32/working/qemu/cpus.c:1541
#7  0x00005556d2f571ca in tcg_exec_all ()
    at /home/zyxu/UniCore32/working/qemu/cpus.c:1574
#8  0x00005556d2f565aa in qemu_tcg_cpu_thread_fn (arg=0x5556d5241000)
    at /home/zyxu/UniCore32/working/qemu/cpus.c:1171
#9  0x00007ff9434e970a in start_thread (arg=0x7ff93f9ca700)
    at pthread_create.c:333
#10 0x00007ff94321f82d in clone ()
    at ../sysdeps/unix/sysv/linux/x86_64/clone.S:109
```

## Create and apply patch

## Busybox

## 如何远程GDB
