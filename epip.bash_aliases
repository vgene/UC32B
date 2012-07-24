#!/bin/bash

WORKING=$HOME/working

working_start()
{
    sudo mount -t tmpfs -o uid=guanxuetao,gid=guanxuetao tmpfs $WORKING
}

working_linux()
{
    cd $WORKING
    git clone /pub/git/linux-unicore.git
    cd $WORKING/linux-unicore
    git branch unicore32 origin/unicore32
    git branch working origin/working
    git branch unicore64 origin/unicore64
}

working_rsync()
{
    cd $WORKING/linux-unicore
    git push origin
    cd $WORKING/qemu
    git push origin
    rsync -ahz /home/guanxuetao/epip/* 192.168.200.62:/home/guanxuetao/epip
    rsync -ahz /pub/initramfs/* 192.168.200.62:/pub/initramfs
    rsync -ahz /pub/bin/* 192.168.200.62:/pub/bin
    rsync -ahz /pub/git/* 192.168.200.62:/pub/git
}

working_stop()
{
    cd $WORKING/linux-unicore
    git st
    cd $WORKING/qemu
    git st
    cd $HOME
    echo -e "\n    INPUT by yourself: sudo umount $WORKING\n"
}

export PATH=/pub/toolchain/uc32/bin:/pub/toolchain/uc64/bin:/pub/bin:$PATH
export LANG=POSIX

alias lynx-1='lynx 192.168.200.1/cgi-bin/openclose.pl'
alias uc32='export ARCH=unicore32'
alias uc64='export ARCH=unicore64'
alias vim-linux='cd ~; ln -sf epip/epip.vimrc.linux .vimrc; cd -'
alias vim-qemu='cd ~; ln -sf epip/epip.vimrc.qemu .vimrc; cd -'
alias makeuc32='uc32; make defconfig; make -j4'
alias makeuc64='uc64; make defconfig; make -j4'
alias makeqemu='uc32; make qemu_defconfig; make zImage -j4'
