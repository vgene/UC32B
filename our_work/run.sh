DIR_WORKING=~/unicore32/working

$DIR_WORKING/qemu-unicore32/bin/qemu-system-unicore32\
                -curses						\
		-M puv3                                         \
                -m 512                                          \
                -icount 0                                       \
                -kernel $DIR_WORKING/zImage  \
