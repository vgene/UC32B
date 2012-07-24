#!/bin/bash

PATCHDIR=~/patches/
PATCHVER=v5             # changed by time

usage()
{
    echo "Usage: (If any error or advice, please contact Guan Xuetao)"
    echo
    echo "    for git commands:"
    echo "        epip-git.sh [format-patch|request-pull|send-email]"
    echo
}

if [ $# == 0 ]; then
    usage
elif [ $1 == "format-patch" ]; then
    git format-patch --thread --cover-letter --subject-prefix=PATCH$PATCHVER    \
        --output-directory $PATCHDIR/qemu-uc32-$PATCHVER                        \
        --cc=blauwirbel@gmail.com                                               \
        --cc=afaerber@suse.de                                                   \
        --cc=chenwj@iis.sinica.edu.tw                                           \
        master..unicore32
    ./scripts/checkpatch.pl $PATCHDIR/qemu-uc32-$PATCHVER/*                     \
        > $PATCHDIR/qemu-uc32-$PATCHVER/checkpatch

elif [ $1 == "request-pull" ]; then
    git request-pull master git://github.com/gxt/QEMU.git unicore32             \
        > $PATCHDIR/qemu-uc32-$PATCHVER/request-pull

elif [ $1 == "send-email" ]; then
    shift
    git send-email --from=gxt@mprc.pku.edu.cn                                   \
        --to=qemu-devel@nongnu.org                                              \
        --subject="[PULL] UniCore32 PUV3 machine support"                       \
        --cc=blauwirbel@gmail.com                                               \
        --cc=afaerber@suse.de                                                   \
        --cc=chenwj@iis.sinica.edu.tw                                           \
        --cc=gxt@mprc.pku.edu.cn                                                \
        $@
else
    usage
fi
