#!/bin/bash
#
# I think most devs just get curse updater or something to keep the libs
# globally. I don't know if that's a good idea or not. Honestly I feel
# pretty nervous about packaging "the newest version" all the time.
#

get_libs () {
    local INLIBS=0
    local FILE
    if [ -f pkgmeta.yaml ]; then
        FILE=pkgmeta.yaml
    else
        FILE=.pkgmeta
    fi

    cat $FILE | while read k v; do
        case $k in
        externals:)
            INLIBS=1
            ;;
        "")
            INLIBS=0
            ;;
        *)
            if [ $INLIBS -eq 1 ]; then
                echo ${v} ${k/:/}
            fi
            ;;
        esac
    done
}

indent () {
    sed -e 's/^/    /'
}

get_libs | while read repo dir; do
    if [ -d $dir ]; then
        echo "Updating $dir"
        (cd $dir && svn up) 2>&1 | indent
    else
        echo "Cloning $repo into $dir"
        svn co $repo $dir 2>&1 | indent
    fi
done
