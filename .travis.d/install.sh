#!/bin/bash

if [[ "$TRAVIS_OS_NAME" == "Linux" ]]; then

  # our path is:
  #   /home/travis/build/NozeIO/Noze.io/

  # Install Swift

  wget "${SWIFT_SNAPSHOT_NAME}"

  TARBALL="`ls swift-*.tar.gz`"
  echo "Tarball: $TARBALL"

  TARPATH="$PWD/$TARBALL"

  cd $HOME # expand Swift tarball in $HOME
  tar zx --strip 1 --file=$TARPATH
  pwd

  export PATH="$PWD/usr/bin:$PATH"
  which swift

  if [ `which swift` ]; then
      echo "Installed Swift: `which swift`"
  else
      echo "Failed to install Swift?"
      exit 42
  fi
  swift --version


  # Environment

  TT_SWIFT_BINARY=`which swift`

  echo "${TT_SWIFT_BINARY}"


  # Install mod_swift

  wget "${MOD_SWIFT}" -O mod_swift.tar.gz
  tar zxf mod_swift.tar.gz
  cd mod_swift-*
  make all
  sudo make install

  swift apache validate


  # Go back somewhere

  cd $HOME

fi
