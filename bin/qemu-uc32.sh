#!/bin/bash

usage()
{
    echo "Usage: (If any error or advice, please contact Guan Xuetao)"
    echo
    echo "    for compile/build:"
    echo "        qemu-uc32.sh [linux-user|softmmu|both]"
    echo
    echo "    for running:"
    echo "        qemu-uc32.sh [fss|test]"
    echo
    echo "Before begin work, working environment should be in:"
    echo "    ~/working/                : your working dir"
    echo
    echo "And following dirs are created perhaps by this script:"
    echo "    ~/working/qemu            : source dir"
    echo "    ~/working/qemu-uc32       : build dir"
    echo
}

# Work environment

WORK_DIR=~/working
LOGFILE=$WORK_DIR/qemu-uc32/build.log
INSTALL_PREFIX=$WORK_DIR/qemu-uc32/install

compile_qemu()
{
    echo "make distclean ..."
    make distclean > $LOGFILE 2>&1
    if [ $? != 0 ]; then
        echo "FAIL in cleaning!"
        return
    fi

    echo "configure ..."
    ./configure --target-list=$TARGETS --enable-debug                           \
	        --interp-prefix=/usr/unicore/gnu-toolchain-unicore/uc32/unicore32-linux/ \
		--disable-sdl                                                   \
		--prefix=$INSTALL_PREFIX                                        \
                >> $LOGFILE 2>&1
    if [ $? != 0 ]; then
        echo "FAIL in configuring!"
        return
    fi

    echo "make ..."
    make -j4 >> $LOGFILE 2>&1
    if [ $? != 0 ]; then
        echo "FAIL in making!"
        return
    fi

    echo "clean old install directory and make install ..."
    make install >> $LOGFILE 2>&1
    if [ $? != 0 ]; then
        echo "FAIL in installing!"
    else
        echo "SUCCESS! See $LOGFILE for detail information."
    fi
}

working()
{
    echo -e "Prepare qemu working environment..."
    cd $WORK_DIR
    git clone /pub/git/qemu.git
    cd $WORKING/qemu
    git branch unicore32 origin/unicore32
    git branch working origin/working
    git co working
    make tags

    echo -e "Prepare qemu-uc32 directory..."
    cd $WORK_DIR
    mkdir qemu-uc32
    cd qemu-uc32
    tar xfj /pub/backup/qemu-unicore32-test-20110318.tar.bz2
    ln -s $WORKING/linux-unicore/arch/unicore32/boot/zImage

    cd $WORKING/qemu
}

testing()
{
    cd $WORK_DIR/qemu-uc32/qemu-unicore32-test
    echo "Most Simple Test"
    unicore32-linux-gcc helloworld.c -o helloworld
    $WORK_DIR/qemu-uc32/install/bin/qemu-unicore32 helloworld

    echo "SPEC2000 CINT"
    cd runSPEC2000-CINT
    ./run_SPEC2000_sim
    cd ..

    echo "SPEC2000 CFP"
    cd runSPEC2000-CFP
    ./runspec2000-f-sim.sh
    cd ..
}

if [ $# == 0 ]; then
    usage
elif [ $1 == "both" ]; then
    TARGETS=unicore32-linux-user,unicore32-softmmu
    compile_qemu
elif [ $1 == "linux-user" ]; then
    TARGETS=unicore32-linux-user
    compile_qemu
elif [ $1 == "softmmu" ]; then
    TARGETS=unicore32-softmmu
    compile_qemu
elif [ $1 == "fss" ]; then
    shift
    $INSTALL_PREFIX/bin/qemu-system-unicore32 -M puv3 -kernel zImage -m 512     \
        -icount auto -append "root=/dev/ram" -curses -D qemu-debug.log $@       \
        | tee fss.log
elif [ $1 == "test" ]; then
    testing
else
    usage
fi
