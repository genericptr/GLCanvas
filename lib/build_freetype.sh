#!/bin/bash

#  Compile-Freetype-For-iOS
#  Original Script https://github.com/jkyin/Compile-Freetype-For-iOS/blob/master/build_freetype.sh
#  Revised by: l'L'l
#
#  New Features Include: auto download latest version, fixed toolchain locations, other various tweeks
#
#  The MIT License (MIT)
#  Copyright (c) 2016 l'L'l
#  ==============================================================================================================
#  Modified for forward compatibility with iOS 8.2+ 
#  (iOS version support < 6.0 tries to link with crt1.3.1.o that is not available in the current versions of iOSs)
#  Included missing "armv7s" slice in the fat binary and removed older "i386" slice
#  Released under same license.
#  =========================================================================================================================
#. Updated to enable bitcode and to generate Position Independent Code (PIC) as expected by current(iOS10+) project standard
#. =========================================================================================================================

BUILD_DIR=$HOME/Desktop/FreeType_iOS_Release # RELEASE_DIR
mkdir -p ${BUILD_DIR}
cd $BUILD_DIR
PACKAGE=$"http://download.savannah.gnu.org/releases/freetype"
LATEST=$(curl -fL ${PACKAGE} | grep -oE "freetype\-\d\.\d\.\d\.tar.gz" | grep -vE "sig|asc" | sed 's/">.*//g' | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | tail -n 1)
#curl -fL ${PACKAGE}/${LATEST} | tar xzf -
VERSION=$(echo $LATEST | sed 's/.tar.gz//g')
cd $VERSION

set -e

iphoneos="8.2"
export CC="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
# custom_flags="--enable-zlib --enable-png --enable-bzip2"
custom_flags="--without-zlib --without-png --without-bzip2 --without-harfbuzz"

ARCH="arm64"
echo "---> Building ${ARCH}-${iphoneos}" | awk '/'${ARCH}'/ {print "\033[34;25;62m" $0 "\033[0m"}'

export CFLAGS="-arch ${ARCH} -pipe -fembed-bitcode -Wno-trigraphs -fpascal-strings -O2 -Wreturn-type -Wunused-variable -fmessage-length=0 -fvisibility=hidden -miphoneos-version-min=$iphoneos -I/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/include/libxml2 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
export AR="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar"
export LDFLAGS="-arch ${ARCH} -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk -miphoneos-version-min=$iphoneos"
./configure --host="aarch64-apple-darwin" --enable-static=yes --enable-shared=no ${custom_flags}
make clean
make
cp objs/.libs/libfreetype.a "${BUILD_DIR}/libfreetype-${ARCH}.a"
build_one="$ARCH"

ARCH="armv7"
echo "---> Building ${ARCH}-${iphoneos}" | awk '/'${ARCH}'/ {print "\033[34;25;62m" $0 "\033[0m"}'

export CFLAGS="-arch ${ARCH} -pipe  -fembed-bitcode -Wno-trigraphs -fpascal-strings -O2 -Wreturn-type -Wunused-variable -fmessage-length=0 -fvisibility=hidden -miphoneos-version-min=$iphoneos -I/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/include/libxml2 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
export AR="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar"
export LDFLAGS="-arch ${ARCH} -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk -miphoneos-version-min=$iphoneos"
./configure --host="${ARCH}-apple-darwin" --enable-static=yes --enable-shared=no ${custom_flags}
make clean
make
cp objs/.libs/libfreetype.a "${BUILD_DIR}/libfreetype-${ARCH}.a"
build_two="$ARCH"

ARCH="armv7s"
echo "---> Building ${ARCH}-${iphoneos}" | awk '/'${ARCH}'/ {print "\033[34;25;62m" $0 "\033[0m"}'

export CFLAGS="-arch ${ARCH} -pipe -fembed-bitcode -Wno-trigraphs -fpascal-strings -O2 -Wreturn-type -Wunused-variable -fmessage-length=0 -fvisibility=hidden -miphoneos-version-min=$iphoneos -I/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/include/libxml2 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
export AR="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar"
export LDFLAGS="-arch ${ARCH} -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk -miphoneos-version-min=$iphoneos"
./configure --host="${ARCH}-apple-darwin" --enable-static=yes --enable-shared=no ${custom_flags}
make clean
make
cp objs/.libs/libfreetype.a "${BUILD_DIR}/libfreetype-${ARCH}.a"
build_three="$ARCH"

ARCH="x86_64"
echo "---> Building ${ARCH}-${iphoneos}" | awk '/'${ARCH}'/ {print "\033[34;25;62m" $0 "\033[0m"}'

export CFLAGS="-arch ${ARCH} -pipe -fembed-bitcode=marker -Wno-trigraphs -fpascal-strings -O2 -Wreturn-type -Wunused-variable -fmessage-length=0 -fvisibility=hidden -miphoneos-version-min=$iphoneos -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk"
export LDFLAGS="-arch ${ARCH} -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -miphoneos-version-min=$iphoneos"
./configure --disable-shared --enable-static --host="${ARCH}-apple-darwin" ${custom_flags}
make clean
make
cp objs/.libs/libfreetype.a "${BUILD_DIR}/libfreetype-${ARCH}.a"
build_four="$ARCH"

echo "---> Success: $build_one $build_two $build_three $build_four" | awk '/Success/ {print "\033[37;35;53m" $0 "\033[0m"}'

lipo -create "${BUILD_DIR}/libfreetype-armv7.a" "${BUILD_DIR}/libfreetype-armv7s.a" "${BUILD_DIR}/libfreetype-arm64.a" "${BUILD_DIR}/libfreetype-x86_64.a" -output "${BUILD_DIR}/libfreetype.a"
lipolog="$(lipo -info ${BUILD_DIR}/libfreetype.a)"

echo "---> $lipolog" | awk '/Arch/ {print "\033[32;35;52m" $0 "\033[0m"}'
echo "---> Build Process Complete!" | awk '/!/ {print "\033[36;35;54m" $0 "\033[0m"}'
