#!/bin/bash

TARGET_DIR=$(pwd)/target
pushd ext/Omb-cs-com/client
make
cp client $TARGET_DIR/usr/bin/omb-client
popd

pushd ext/ttdnsd/
make clean
DESTDIR=$TARGET_DIR make install
popd
