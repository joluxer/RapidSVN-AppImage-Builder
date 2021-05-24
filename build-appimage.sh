#!/bin/bash

PROGDIR=$(dirname $(readlink -f $0))

# check development tools
test -n "$(which lddtree 2>/dev/null)" || { res=$?; echo "you need the tool 'lddtree' from the 'app-misc/pax-utils' package"; exit $res; }
test -n "$(which gcc-config 2>/dev/null)" || { res=$?; echo "you need the tool 'gcc-config'"; exit $res; }
test -n "$(which git 2>/dev/null)" || { res=$?; echo "you need the tool 'git'"; exit $res; }
test -n "$(which wget 2>/dev/null)" || { res=$?; echo "you need the tool 'wget'"; exit $res; }

export APPDIR=$(readlink -f $PROGDIR/AppDir)
export VERSION=0.13
export LD_LIBRARY_PATH=$APPDIR/usr/lib
GCCLIBDIR=$(gcc-config -L | tr ':' '\n' | grep -v /32)

# prepare build with git checkout
GITDIR=$PROGDIR/git-checkout
GITURL=https://github.com/joluxer/RapidSVN.git
GITBRANCH=hotfixes
GITREVISON=HEAD

BUILDDIR=$(readlink -f $GITDIR)

TOOLSDIR=$(readlink -f $PROGDIR/tools-download)

# get all the tools
export PATH="$TOOLSDIR:$PATH"

LINUXDEPLOY=$( { which linuxdeploy || which linuxdeploy-x86_64 || which linuxdeploy-x86_64.AppImage; } 2>/dev/null)
test -n "$LINUXDEPLOY" || wget --unlink --continue --directory-prefix=$TOOLSDIR https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage || exit $?
LINUXDEPLOY=$( { which linuxdeploy || which linuxdeploy-x86_64 || which linuxdeploy-x86_64.AppImage; } 2>/dev/null)
test -x "$LINUXDEPLOY" || chmod +x "$LINUXDEPLOY" || exit $?

APPIMAGETOOL=$( { which appimagetool || which appimagetool-x86_64 || which appimagetool-x86_64.AppImage; } 2>/dev/null)
test -n "$APPIMAGETOOL" || wget --unlink --continue --directory-prefix=$TOOLSDIR https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage || exit $?
APPIMAGETOOL=$( { which appimagetool || which appimagetool-x86_64 || which appimagetool-x86_64.AppImage; } 2>/dev/null)
test -x "$APPIMAGETOOL" || chmod +x "$APPIMAGETOOL" || exit $?

LINUXDEPLOYCHECKRT=$($LINUXDEPLOY --list-plugins 2>&1 | grep checkrt | cut -d' ' -f 2)
test -n "$LINUXDEPLOYCHECKRT" || wget --unlink --continue --directory-prefix=$TOOLSDIR https://github.com/linuxdeploy/linuxdeploy-plugin-checkrt/releases/download/continuous/linuxdeploy-plugin-checkrt-x86_64.sh || exit $?
LINUXDEPLOYCHECKRT=$($LINUXDEPLOY --list-plugins 2>&1 | grep checkrt | cut -d' ' -f 2)
test -x "$LINUXDEPLOYCHECKRT" || chmod +x "$LINUXDEPLOYCHECKRT" || exit $?

#echo $( { which linuxdeploy || which linuxdeploy-x86_64 || which linuxdeploy-x86_64.AppImage; } 2>/dev/null)
#echo $( { which appimagetool || which appimagetool-x86_64 || which appimagetool-x86_64.AppImage; } 2>/dev/null)
#echo $($LINUXDEPLOY --list-plugins 2>&1 | grep checkrt | cut -d' ' -f 2)

# clone, change branch, build
test -r $GITDIR/autogen.sh || {
    rm -rf $GITDIR
    git clone $GITURL $GITDIR || exit $?
}

(
    cd $GITDIR || exit $?
    git fetch --all
    git checkout $GITBRANCH || exit $?
    git checkout $GITREVISION || exit $?
) || exit $?

mkdir -p $BUILDDIR || exit $? && (
    cd $BUILDDIR || exit $?

    test -r configure || { $GITDIR/autogen.sh || exit $?; }
    test -r Makefile || { ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var || exit $?; }
    make -j $(( $(nproc) * 2)) || exit $?
    mkdir -p $APPDIR || exit $?
    make install DESTDIR=$APPDIR || exit $?
) || exit $?

mkdir -p $APPDIR/usr/optional/libstdc++ $APPDIR/usr/optional/libgcc_s

cp -a $GCCLIBDIR/libstdc++.so* $APPDIR/usr/optional/libstdc++
cp -a $GCCLIBDIR/libgcc_s.so* $APPDIR/usr/optional/libgcc_s

for res in 128x128 16x16 32x32 48x48; do
    mkdir -p $APPDIR/usr/share/icons/hicolor/$res/apps
    cp $BUILDDIR/librapidsvn/src/res/bitmaps/rapidsvn_$res.png $APPDIR/usr/share/icons/hicolor/$res/apps/rapidsvn.png
done

$LINUXDEPLOY --appdir=$APPDIR -d $BUILDDIR/packages/debian/rapidsvn.desktop -e $APPDIR/usr/bin/rapidsvn --plugin=checkrt || {
    chmod -R u+w $APPDIR

    $LINUXDEPLOY \
                   --appdir=$APPDIR -d $BUILDDIR/packages/debian/rapidsvn.desktop -e $APPDIR/usr/bin/rapidsvn --plugin=checkrt
}

STATIC_BLACKLIST=(libapr-1.so.0 libaprutil-1.so.0 libmount.so.1 libgtk-x11-2.0.so.0 libgdk-x11-2.0.so.0 libcairo.so.2 libgdk_pixbuf-2.0.so.0 libnotify.so.4 libSDL2-2.0.so.0 libXxf86vm.so.1)

for l in "${STATIC_BLACKLIST[@]}"; do
    echo -n "remove blacklisted library $l: "
    find $APPDIR -name "$l"'*' -print -delete || echo "(nothing to do)"
done

# remove everything, that has a parent in the running system
echo "removing indirect blacklisted:"
lddtree $APPDIR/usr/bin/rapidsvn | awk -f $PROGDIR/list-sysparented-libs.awk appdir=$APPDIR | tee /dev/stderr | xargs rm

$APPIMAGETOOL $APPDIR -g

