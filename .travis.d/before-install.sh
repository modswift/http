#!/bin/bash

if [[ "$TRAVIS_OS_NAME" == "Linux" ]]; then
    sudo apt-get install -y wget \
       clang-3.6 libc6-dev make git libicu52 libicu-dev \
       git autoconf libtool pkg-config \
       libblocksruntime-dev \
       libkqueue-dev \
       libpthread-workqueue-dev \
       systemtap-sdt-dev \
       libbsd-dev libbsd0 libbsd0-dbg \
       curl libcurl4-openssl-dev \
       libedit-dev \
       python2.7 python2.7-dev \
       \
       pkg-config libapr1-dev libaprutil1-dev \
       libxml2 apache2 apache2-dev \
       libaprutil1-dbd-sqlite3 \
       libaprutil1-dbd-pgsql

    # Not available on Trusty: libnghttp2-dev

    sudo update-alternatives --quiet --install /usr/bin/clang clang /usr/bin/clang-3.6 100
    sudo update-alternatives --quiet --install /usr/bin/clang++ clang++ /usr/bin/clang++-3.6 100
else
    echo "OS: $TRAVIS_OS_NAME"
    echo "mod_swift: update brew:"
    brew update --quiet >/dev/null 2>&1
    echo "mod_swift: done, tap modswift/mod_swift"
    brew tap modswift/mod_swift
    echo "done, install httpd ..."
    brew install httpd --with-mpm-event --with-http2
    echo "done, install mod_swift ..."
    brew install mod_swift
fi
