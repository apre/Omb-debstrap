#!/bin/bash

# Todo:
# - check the build result
# - import configure mailpile
# - clean startup scripts
# - script inline help
# - overload GITHUB_ROOT
# - build deb
#



# immediate exit in case of any error.
set -e

DEB_PACKAGE_FILENAME=own-mailbox.deb

export GITHUB_ROOT=https://github.com/apre

TARGET_DIR=$(pwd)/build

if [ ! -d "$TARGET_DIR" ]; then
mkdir -p $TARGET_DIR
fi

if [ ! -d "ext" ]; then
mkdir -p ext
fi


cd ext

echo "checking if requiered repositories are here."

if [ ! -d "Omb-cs-com" ]; then
git clone $GITHUB_ROOT/Omb-cs-com
fi

if [ ! -d "Omb-ihm" ]; then
git clone $GITHUB_ROOT/Omb-ihm
fi

if [ ! -d "Omb-Mailpile" ]; then
git clone $GITHUB_ROOT/Omb-Mailpile
fi

if [ ! -d "ttdnsd" ]; then
git clone $GITHUB_ROOT/ttdnsd
fi

cd ..

echo prepare own-mailbox configuration
cp -rf target/* $TARGET_DIR

echo building omb-client
pushd ext/Omb-cs-com/client
make
cp client $TARGET_DIR/usr/bin/omb-client
popd

echo building ttdnsd
pushd ext/ttdnsd/
make clean
DESTDIR=$TARGET_DIR make install
popd

echo preparing mailpile component
cd ext/Omb-Mailpile
mkdir -p $TARGET_DIR/usr/share/omb/Mailpile
git checkout-index -a -f --prefix=$TARGET_DIR/usr/share/omb/Mailpile
cd $TARGET_DIR/usr/share/omb/Mailpile/
virtualenv   mp-virtualenv
#virtualenv --relocatable mp-virtualenv
#source mp-virtualenv/bin/activate
#pip install -r requirements.txt



echo building debian package $DEB_PACKAGE_FILENAME

chmod 755 $TARGET_DIR/DEBIAN/post*
chmod 755 $TARGET_DIR/DEBIAN/pre*

sudo dpkg-deb --build ./build $DEB_PACKAGE_FILENAME

du -hs $DEB_PACKAGE_FILENAME

echo Done.

