#!/bin/bash

PATCHDIR=~/patches
#PATCHVER=v2                                    # changed by time
#PATCHDIR=~/patches/qemu-uc32-$PATCHVER

usage()
{
    echo "Usage: (If any error or advice, please contact Guan Xuetao)"
    echo
    echo "  for git commands:"
    echo "      mygit.sh [qemu-format-patch | linux-format-patch] master..unicore32"
    echo "      mygit.sh [qemu-request-pull | linux-request-pull]"
    echo "      mygit.sh [qemu-send-email | linux-send-email] filename or m..u"
    echo
}

if [ $# == 0 ]; then
    usage
elif [ $1 == "qemu-format-patch" ]; then
    shift
    git format-patch --thread --cover-letter --subject-prefix=PATCH$PATCHVER    \
        --output-directory $PATCHDIR                                            \
        --cc=blauwirbel@gmail.com                                               \
        --cc=afaerber@suse.de                                                   \
        --cc=chenwj@iis.sinica.edu.tw                                           \
        $@
    ./scripts/checkpatch.pl $PATCHDIR/* > $PATCHDIR/checkpatch

elif [ $1 == "qemu-request-pull" ]; then
    git request-pull master git://github.com/gxt/QEMU.git unicore32      \
        > $PATCHDIR/request-pull
elif [ $1 == "qemu-send-email" ]; then
    shift
    git send-email --from=gxt@mprc.pku.edu.cn                                   \
        --to=qemu-devel@nongnu.org                                              \
        --cc=aliguori@us.ibm.com                                                \
        --cc=blauwirbel@gmail.com                                               \
        --cc=afaerber@suse.de                                                   \
        --cc=gxt@mprc.pku.edu.cn                                                \
        $@
#        --subject="[RESEND PULL REQUEST] UniCore32 PUV3 machine support"        \

elif [ $1 == "binutils-send-email" ]; then
    shift
    git send-email --from=gxt@mprc.pku.edu.cn                                   \
        --to=linux-unicore@freelists.org                                        \
        $@
#        --subject="[RESEND PULL REQUEST] UniCore32 PUV3 machine support"        \

elif [ $1 == "linux-request-pull" ]; then
#   git tag for-linus unicore32 -f -s -u gxt@mprc.pku.edu.cn
#   git push -f --tag
#   cd git-dir; git push github -f --tag
    git request-pull master git://github.com/gxt/linux.git for-linus            \
        > $PATCHDIR/unicore32-request-pull
    gpg -o $PATCHDIR/unicore32-request-pull.sig                                 \
        --clearsign $PATCHDIR/unicore32-request-pull
    mail -s "[GIT PULL REQUEST] UniCore32 update for v3.7-rc4"                   \
        -c linux-kernel@vger.kernel.org                                          \
        torvalds@linux-foundation.org  < $PATCHDIR/unicore32-request-pull.sig

elif [ $1 == "linux-send-email" ]; then
    shift
#        --cc=torvalds@linux-foundation.org
#        --cc=gang.chen.5i5j@gmail.com
#        --cc=sunzc522@gmail.com
#        --subject="[GIT PULL] unicore32 fixes for v3.7-rc1 "
    git send-email --from=gxt@mprc.pku.edu.cn                                   \
        --to=linux-kernel@vger.kernel.org                                       \
        --cc=gxt@mprc.pku.edu.cn                                                \
        $@
else
    usage
fi
