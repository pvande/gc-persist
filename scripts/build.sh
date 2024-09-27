#!/bin/sh

# Usage:
# ./scripts/build.sh <target_dir>
#
#   <target> is the directory where the compiled extension will be written to

set -e

lib="gc-escape"

platform=$(uname)
case $platform in
  Linux)
    target="${1}/native/linux-amd64"
    mkdir -p $target
    clang -shared \
          -isystem include -fPIC \
          -o ${target}/${lib}.so \
          ${lib}.c;;

  Darwin)
    target="${1}/native/macos"
    mkdir -p $target
    clang -shared \
          -arch x86_64 -arch arm64 \
          -isystem include -fPIC \
          -o ${target}/${lib}.dylib \
          ${lib}.c;;

  MINGW*)
    if [ -z "$MINGW_DIR" ]; then
      echo "Please set the MINGW_DIR environment variable when building for Windows."
      exit 1
    fi

    target="${1}/native/windows-amd64"
    mkdir -p $target
    clang -shared \
          --sysroot=$MINGW_DIR \
          --target=x86_64-w64-mingw32 \
          -fuse-ld=lld \
          -isystem include -lws2_32 \
          -o ${target}/${lib}.dll \
          ${lib}.c;;

  *)
    echo "Unsupported platform: $platform" >&2
    exit 1;;
esac
