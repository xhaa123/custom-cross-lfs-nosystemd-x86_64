#!/bin/bash

function checkBuiltPackage() {

echo "Did everything build fine?: [Y/N]"
while read -n1 -r -p "[Y/N]   " && [[ $REPLY != q ]]; do
  case $REPLY in
    Y) break 1;;
    N) echo "$EXIT"
       echo "Fix it!"
       exit 1;;
    *) echo " Try again. Type y or n";;
  esac
done

}

function as_root()
{
  if   [ $EUID = 0 ];        then $*
  elif [ -x /usr/bin/sudo ]; then sudo $*
  else                            su -c \\"$*\\"
  fi
}

export -f as_root

function buildSingleXLib32() {
  PKG_CONFIG_PATH="${PKG_CONFIG_PATH32}" \
  USE_ARCH=32 CC="gcc ${BUILD32}" CXX="g++ ${BUILD32}" ./configure $XORG_CONFIG32
  make PREFIX=/usr LIBDIR=/usr/lib
  as_root make PREFIX=/usr LIBDIR=/usr/lib install
}

export -f buildSingleXLib32

function buildSingleXLib64() {
  PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
  USE_ARCH=64 CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" ./configure $XORG_CONFIG64
  make PREFIX=/usr LIBDIR=/usr/lib64
  as_root make PREFIX=/usr LIBDIR=/usr/lib64 install
}


export -f buildSingleXLib64

#Building the final CLFS System
CLFS=/
CLFSHOME=/home
CLFSSOURCES=/sources
CLFSTOOLS=/tools
CLFSCROSSTOOLS=/cross-tools
CLFSFILESYSTEM=ext4
CLFSROOTDEV=/dev/sda4
CLFSHOMEDEV=/dev/sda5
MAKEFLAGS='j8'
BUILD32="-m32"
BUILD64="-m64"
CLFS_TARGET32="i686-pc-linux-gnu"
PKG_CONFIG_PATH32=/usr/lib/pkgconfig
PKG_CONFIG_PATH64=/usr/lib64/pkgconfig

export CLFS=/
export CLFSUSER=clfs
export CLFSHOME=/home
export CLFSSOURCES=/sources
export CLFSTOOLS=/tools
export CLFSCROSSTOOLS=/cross-tools
export CLFSFILESYSTEM=ext4
export CLFSROOTDEV=/dev/sda4
export CLFSHOMEDEV=/dev/sda5
export MAKEFLAGS=j8
export BUILD32="-m32"
export BUILD64="-m64"
export CLFS_TARGET32="i686-pc-linux-gnu"
export PKG_CONFIG_PATH32=/usr/lib/pkgconfig
export PKG_CONFIG_PATH64=/usr/lib64/pkgconfig

#Let's continue
#Final system is seperated into several parts 
#to make bugfixing and maintenance easier

cd ${CLFSSOURCES}

mkdir xc && cd xc

export XORG_PREFIX="/usr"
export XORG_CONFIG32="--prefix=$XORG_PREFIX --sysconfdir=/etc --localstatedir=/var \
  --libdir=$XORG_PREFIX/lib"
export XORG_CONFIG64="--prefix=$XORG_PREFIX --sysconfdir=/etc --localstatedir=/var \
  --libdir=$XORG_PREFIX/lib64"


cat > /etc/profile.d/xorg.sh << EOF
export XORG_PREFIX="/usr"
export XORG_CONFIG32="--prefix=$XORG_PREFIX --sysconfdir=/etc --localstatedir=/var \
  --libdir=$XORG_PREFIX/lib"
export XORG_CONFIG64="--prefix=$XORG_PREFIX --sysconfdir=/etc --localstatedir=/var \
  --libdir=$XORG_PREFIX/lib64"
EOF

chmod 644 /etc/profile.d/xorg.sh

#util-macros 32-bit
wget https://www.x.org/pub/individual/util/util-macros-1.19.1.tar.bz2 -O \
  util-macros-1.19.1.tar.bz2
  
mkdir util-macros && tar xf util-macros-*.tar.* -C util-macros --strip-components 1
cd util-macros


PKG_CONFIG_PATH="${PKG_CONFIG_PATH32}" \
USE_ARCH=32 CC="gcc ${BUILD32}" CXX="g++ ${BUILD32}" ./configure $XORG_CONFIG32
as_root make PREFIX=/usr LIBDIR=/usr/lib install

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf util-macros

#util-macros 64-bit
  
mkdir util-macros && tar xf util-macros-*.tar.* -C util-macros --strip-components 1
cd util-macros

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
USE_ARCH=64 CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" ./configure $XORG_CONFIG64
as_root make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf util-macros

#Xorg Protocol Headers 
cat > proto-7.md5 << "EOF"
1a05fb01fa1d5198894c931cf925c025  bigreqsproto-1.1.2.tar.bz2
98482f65ba1e74a08bf5b056a4031ef0  compositeproto-0.4.2.tar.bz2
998e5904764b82642cc63d97b4ba9e95  damageproto-1.2.1.tar.bz2
4ee175bbd44d05c34d43bb129be5098a  dmxproto-2.3.1.tar.bz2
b2721d5d24c04d9980a0c6540cb5396a  dri2proto-2.8.tar.bz2
a3d2cbe60a9ca1bf3aea6c93c817fee3  dri3proto-1.0.tar.bz2
e7431ab84d37b2678af71e29355e101d  fixesproto-5.0.tar.bz2
36934d00b00555eaacde9f091f392f97  fontsproto-2.1.3.tar.bz2
5565f1b0facf4a59c2778229c1f70d10  glproto-1.4.17.tar.bz2
b290a463af7def483e6e190de460f31a  inputproto-2.3.2.tar.bz2
94afc90c1f7bef4a27fdd59ece39c878  kbproto-1.0.7.tar.bz2
92f9dda9c870d78a1d93f366bcb0e6cd  presentproto-1.1.tar.bz2
a46765c8dcacb7114c821baf0df1e797  randrproto-1.5.0.tar.bz2
1b4e5dede5ea51906f1530ca1e21d216  recordproto-1.14.2.tar.bz2
a914ccc1de66ddeb4b611c6b0686e274  renderproto-0.11.1.tar.bz2
cfdb57dae221b71b2703f8e2980eaaf4  resourceproto-1.2.0.tar.bz2
edd8a73775e8ece1d69515dd17767bfb  scrnsaverproto-1.2.2.tar.bz2
fe86de8ea3eb53b5a8f52956c5cd3174  videoproto-2.3.3.tar.bz2
5f4847c78e41b801982c8a5e06365b24  xcmiscproto-1.2.2.tar.bz2
70c90f313b4b0851758ef77b95019584  xextproto-7.3.0.tar.bz2
120e226ede5a4687b25dd357cc9b8efe  xf86bigfontproto-1.2.0.tar.bz2
a036dc2fcbf052ec10621fd48b68dbb1  xf86dgaproto-2.1.tar.bz2
1d716d0dac3b664e5ee20c69d34bc10e  xf86driproto-2.1.1.tar.bz2
e793ecefeaecfeabd1aed6a01095174e  xf86vidmodeproto-2.3.1.tar.bz2
9959fe0bfb22a0e7260433b8d199590a  xineramaproto-1.2.1.tar.bz2
16791f7ca8c51a20608af11702e51083  xproto-7.0.31.tar.bz2
EOF

mkdir proto &&
cd proto &&
grep -v '^#' ../proto-7.md5 | awk '{print $2}' | wget -i- -c \
    -B https://www.x.org/pub/individual/proto/ &&
md5sum -c ../proto-7.md5


USE_ARCH="" CC="" CXX="" PKG_CONFIG_PATH="" LIBDIR=""

USE_ARCH=32 CC="gcc ${BUILD32}" CXX="g++ ${BUILD32}" 
PKG_CONFIG_PATH="${PKG_CONFIG_PATH32}"

for package in $(grep -v '^#' ../proto-7.md5 | awk '{print $2}')
do
  packagedir=${package%.tar.bz2}
  tar -xf $package
  pushd $packagedir  
  ./configure $XORG_CONFIG32  
  as_root make PREFIX=/usr LIBDIR=/usr/lib install
  popd
  rm -rf $packagedir
done

checkBuiltPackage

USE_ARCH="" CC="" CXX="" PKG_CONFIG_PATH=""

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"
USE_ARCH=64 CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}"

for package in $(grep -v '^#' ../proto-7.md5 | awk '{print $2}')
do
  packagedir=${package%.tar.bz2}
  tar -xf $package
  pushd $packagedir  
  ./configure $XORG_CONFIG64
  as_root make PREFIX=/usr LIBDIR=/usr/lib64 install
  popd
  rm -rf $packagedir
done

cd ${CLFSSOURCES}/xc

checkBuiltPackage

USE_ARCH="" CC="" CXX="" PKG_CONFIG_PATH="" LIBDIR=""

#libXau 32-bit
wget https://www.x.org/pub/individual/lib/libXau-1.0.8.tar.bz2 -O \
  libXau-1.0.8.tar.bz2
  
mkdir libxau && tar xf libXau-*.tar.* -C libxau --strip-components 1
cd libxau

buildSingleXLib32

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf libxau

#libXau 64-bit
mkdir libxau && tar xf libXau-*.tar.* -C libxau --strip-components 1
cd libxau

buildSingleXLib64

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf libxau

#libXdmcp 32-bit
wget https://www.x.org/pub/individual/lib/libXdmcp-1.1.2.tar.bz2 -O \
  libXdcmp-1.1.2.tar.bz2

mkdir libxdcmp && tar xf libXdcmp-*.tar.* -C libxdcmp --strip-components 1
cd libxdcmp

buildSingleXLib32

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf libxdcmp

#libXdmcp 64-bit
mkdir libxdcmp && tar xf libXdcmp-*.tar.* -C libxdcmp --strip-components 1
cd libxdcmp

buildSingleXLib64

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf libxdcmp

#libffi 32-bit
wget ftp://sourceware.org/pub/libffi/libffi-3.2.1.tar.gz -O \
  libffi-3.2.1.tar.gz

mkdir libffi && tar xf libffi-*.tar.* -C libffi --strip-components 1
cd libffi

buildSingleXLib32

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf libffi

#libffi 32-bit
mkdir libffi && tar xf libffi-*.tar.* -C libffi --strip-components 1
cd libffi

buildSingleXLib64

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf libffi

cd ${CLFSSOURCES}

#Expat (Needed by Python) 32-bit
wget http://downloads.sourceforge.net/expat/expat-2.1.0.tar.gz -O \
  expat-2.1.0.tar.gz

mkdir expat && tar xf expat-*.tar.* -C expat --strip-components 1
cd expat

USE_ARCH=32 PKG_CONFIG_PATH="${PKG_CONFIG_PATH32}"
CC="gcc ${BUILD32}" CXX="g++ ${BUILD32}" 
./configure --prefix=/usr \
  --libdir=/usr/lib \
  --disable-static \
  --enable-shared
  
make LIBDIR=/usr/lib PREFIX=/usr 
as_root make LIBDIR=/usr/lib PREFIX=/usr install
  
install -v -m755 -d /usr/share/doc/expat-2.1.0 &&
install -v -m644 doc/*.{html,png,css} /usr/share/doc/expat-2.1.0

cd ${CLFSSOURCES}
checkBuiltPackage
rm -rf expat


#Expat (Needed by Python) 64-bit
mkdir expat && tar xf expat-*.tar.* -C expat --strip-components 1
cd expat

USE_ARCH=64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"
CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" 
./configure --prefix=/usr \
  --libdir=/usr/lib64 \
  --disable-static \
  --enable-shared
  
make LIBDIR=/usr/lib64 PREFIX=/usr 
as_root make LIBDIR=/usr/lib64 PREFIX=/usr install
  
install -v -m755 -d /usr/share/doc/expat-2.1.0 &&
install -v -m644 doc/*.{html,png,css} /usr/share/doc/expat-2.1.0

cd ${CLFSSOURCES}
checkBuiltPackage
rm -rf expat

#Python2.7.6 64-bit
wget https://www.python.org/ftp/python/2.7.13/Python-2.7.13.tar.xz -O \
  Python-2.7.13.tar.xz
  
wget https://www.williamfeely.info/download/lfs-multilib/Python-2.7.13-multilib-1.patch -O \
  python-2713-multilib-1.patch

wget https://www.python.org/ftp/python/doc/2.7.13/python-2.7.13-docs-html.tar.bz2 -O \
  python-2.7.13-docs-html.tar.bz2
  
mkdir Python-2 && tar xf Python-2.7.13.tar.* -C Python-2 --strip-components 1
cd Python-2

patch -Np1 -i ../python-276-multilib-1.patch

sed -i -e "s|@@MULTILIB_DIR@@|/lib64|g" Lib/distutils/command/install.py \
       Lib/distutils/sysconfig.py \
       Lib/pydoc.py \
       Lib/site.py \
       Lib/sysconfig.py \
       Lib/test/test_dl.py \
       Lib/test/test_site.py \
       Lib/trace.py \
       Makefile.pre.in \
       Modules/getpath.c \
       setup.py
       
sed -i "s@/usr/X11R6@${XORG_PREFIX}@g" setup.py

sed -i 's@lib/python@lib64/python@g' Modules/getpath.c

USE_ARCH=64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" 
CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" LDFLAGS="-L/usr/lib64"
./configure --prefix=/usr       \
            --enable-shared     \
            --with-system-expat \
            --with-system-ffi   \
            --enable-unicode=ucs4 \
            --libdir=/usr/lib64

make EXTRA_CFLAGS="-fwrapv" LIBDIR=/usr/lib64 PREFIX=/usr 
as_root make EXTRA_CFLAGS="-fwrapv" LIBDIR=/usr/lib64 PREFIX=/usr install

chmod -v 755 /usr/lib/libpython2.7.so.1.0

mv -v /usr/bin/python{,-64} &&
mv -v /usr/bin/python2{,-64} &&
mv -v /usr/bin/python2.7{,-64} &&
ln -sfv python2.7-64 /usr/bin/python2-64 &&
ln -sfv python2-64 /usr/bin/python-64 &&
ln -sfv multiarch_wrapper /usr/bin/python &&
ln -sfv multiarch_wrapper /usr/bin/python2 &&
ln -sfv multiarch_wrapper /usr/bin/python2.7 &&
mv -v /usr/include/python2.7/pyconfig{,-64}.h

install -v -dm755 /usr/share/doc/python-2.7.6 &&

tar --strip-components=1                     \
    --no-same-owner                          \
    --directory /usr/share/doc/python-2.7.6 \
    -xvf ../python-2.7.6-docs-html.tar.bz2 &&

find /usr/share/doc/python-2.7.6 -type d -exec chmod 0755 {} \; &&
find /usr/share/doc/python-2.7.6 -type f -exec chmod 0644 {} \;

            
cd ${CLFSSOURCES}
checkBuiltPackage
rm -rf Python-2

cd ${CLFSSOURCES}
