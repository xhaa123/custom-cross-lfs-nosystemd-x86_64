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

patch -Np1 -i ../python-2.7.12-lib64.patch

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
            --libdir=/usr/lib64 \
            --platlib=/usr/lib64

make EXTRA_CFLAGS="-fwrapv" PLATLIB=/usr/lib64 LIBDIR=/usr/lib64 PREFIX=/usr 
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

#Python 3 64-bit
wget https://www.python.org/ftp/python/3.6.0/Python-3.6.0.tar.xz -O \
  Python-3.6.0.tar.xz

wget http://pkgs.fedoraproject.org/cgit/rpms/python3.git/plain/00102-lib64.patch -O \
  python360-multilib.patch
  
wget https://docs.python.org/3.6/archives/python-3.6.0-docs-html.tar.bz2 -O \
  python-360-docs.tar.bz2
  
mkdir Python-3 && tar xf Python-3.6*.tar.xz -C Python-3 --strip-components 1
cd Python-3

patch -Np1 -i ../python360-multilib.patch

USE_ARCH=64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"
CXX="/usr/bin/g++ ${BUILD64}" CC="/usr/bin/gcc ${BUILD64}"
./configure --prefix=/usr       \
            --enable-shared     \
            --with-system-expat \
            --with-system-ffi   \
            --libdir=/usr/lib64 \
            --with-custom-platlibdir=/usr/lib64 \
            --with-ensurepip=yes &&

make PREFIX=/usr LIBDIR=/usr/lib64 PLATLIBDIR=/usr/lib64 platlibdir=/usr/lib64
as_root make install PREFIX=/usr LIBDIR=/usr/lib64 PLATLIBDIR=/usr/lib64 \
  platlibdir=/usr/lib64

chmod -v 755 /usr/lib/libpython3.6m.so &&
chmod -v 755 /usr/lib/libpython3.so

install -v -dm755 /usr/share/doc/python-3.6.0/html &&
tar --strip-components=1 \
    --no-same-owner \
    --no-same-permissions \
    -C /usr/share/doc/python-3.6.0/html \
    -xvf ../python-3.6.0-docs-html.tar.bz2

ln -svfn python-3.6.0 /usr/share/doc/python-3

cd ${CLFSSOURCES}
checkBuiltPackage
rm -rf Python-3

cd ${CLFSSOURCES}/xc

#xcb-proto 32-bit
wget http://xcb.freedesktop.org/dist/xcb-proto-1.12.tar.bz2 -O \
  xcb-proto-1.12.tar.bz2
wget http://www.linuxfromscratch.org/patches/blfs/svn/xcb-proto-1.12-python3-1.patch -O \
  xcb-proto-1.12-python3-1.patch
wget http://www.linuxfromscratch.org/patches/blfs/svn/xcb-proto-1.12-schema-1.patch -O \
  xcb-proto-1.12-schema-1.patch

mkdir xcb-proto && tar xf xcb-proto-1.12.tar.* -C xcb-proto --strip-components 1
cd xcb-proto

patch -Np1 -i ../xcb-proto-1.12-schema-1.patch

patch -Np1 -i ../xcb-proto-1.12-python3-1.patch

PYTHONHOME="/usr/lib64/python3.6/"
PYTHONPATH="/usr/lib64/python3.6/"
USE_ARCH=32 PKG_CONFIG_PATH="${PKG_CONFIG_PATH32}"
CXX="/usr/bin/g++ ${BUILD32}" CC="/usr/bin/gcc ${BUILD32}

./configure $XORG_CONFIG32

make check

make PREFIX=/usr LIBDIR=/usr/lib
make PREFIX=/usr LIBDIR=/usr/lib install

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf xcb-proto

#xcb-proto 64-bit
wget http://xcb.freedesktop.org/dist/xcb-proto-1.12.tar.bz2 -O \
  xcb-proto-1.12.tar.bz2
wget http://www.linuxfromscratch.org/patches/blfs/svn/xcb-proto-1.12-python3-1.patch -O \
  xcb-proto-1.12-python3-1.patch
wget http://www.linuxfromscratch.org/patches/blfs/svn/xcb-proto-1.12-schema-1.patch -O \
  xcb-proto-1.12-schema-1.patch

mkdir xcb-proto && tar xf xcb-proto-1.12.tar.* -C xcb-proto --strip-components 1
cd xcb-proto

patch -Np1 -i ../xcb-proto-1.12-schema-1.patch

patch -Np1 -i ../xcb-proto-1.12-python3-1.patch

PYTHONHOME="/usr/lib64/python3.6/"
PYTHONPATH="/usr/lib64/python3.6/"
USE_ARCH=64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"
CXX="/usr/bin/g++ ${BUILD64}" CC="/usr/bin/gcc ${BUILD64}

./configure $XORG_CONFIG64

make check

make PREFIX=/usr LIBDIR=/usr/lib64
make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf xcb-proto

#libxcb 32-bit
wget http://xcb.freedesktop.org/dist/libxcb-1.12.tar.bz2 -O \
  libxcb-1.12.tar.bz2

wget http://www.linuxfromscratch.org/patches/blfs/svn/libxcb-1.12-python3-1.patch -O \
  libxcb-1.12-python3-1.patch

mkdir libxcb && tar xf libxcb-*.tar.* -C libxcb --strip-components 1
cd libxcb

patch -Np1 -i ../libxcb-1.12-python3-1.patch

sed -i "s/pthread-stubs//" configure

PYTHONHOME="/usr/lib64/python3.6/"
PYTHONPATH="/usr/lib64/python3.6/"
USE_ARCH=32 PKG_CONFIG_PATH="${PKG_CONFIG_PATH32}"
CXX="g++ ${BUILD32}" CC="gcc ${BUILD32}

./configure $XORG_CONFIG32    \
            --enable-xinput   \
            --without-doxygen \
            --libdir=/usr/lib \
            --without-doxygen \
            --docdir='${datadir}'/doc/libxcb-1.12 &&
            
make PREFIX=/usr LIBDIR=/usr/lib
make PREFIX=/usr LIBDIR=/usr/lib install

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf libxdcmp

#libxcb 64-bit
mkdir libxcb && tar xf libxcb-*.tar.* -C libxcb --strip-components 1
cd libxcb

patch -Np1 -i ../libxcb-1.12-python3-1.patch
sed -i "s/pthread-stubs//" configure

PYTHONHOME="/usr/lib64/python3.6/"
PYTHONPATH="/usr/lib64/python3.6/"
USE_ARCH=64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"
CXX="g++ ${BUILD64}" CC="gcc ${BUILD64}

./configure $XORG_CONFIG64     \
            --enable-xinput   \
            --without-doxygen \
            --libdir=/usr/lib64 \
            --without-doxygen \
            --docdir='${datadir}'/doc/libxcb-1.12 &&
            
make PREFIX=/usr LIBDIR=/usr/lib64
make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc
checkBuiltPackage
rm -rf libxdcmp

cat > lib-7.md5 << "EOF"
c5ba432dd1514d858053ffe9f4737dd8  xtrans-1.3.5.tar.bz2
0f618db70c4054ca67cee0cc156a4255  libX11-1.6.5.tar.bz2
52df7c4c1f0badd9f82ab124fb32eb97  libXext-1.3.3.tar.bz2
d79d9fe2aa55eb0f69b1a4351e1368f7  libFS-1.0.7.tar.bz2
addfb1e897ca8079531669c7c7711726  libICE-1.0.9.tar.bz2
499a7773c65aba513609fe651853c5f3  libSM-1.2.2.tar.bz2
7a773b16165e39e938650bcc9027c1d5  libXScrnSaver-1.2.2.tar.bz2
8f5b5576fbabba29a05f3ca2226f74d3  libXt-1.1.5.tar.bz2
41d92ab627dfa06568076043f3e089e4  libXmu-1.1.2.tar.bz2
20f4627672edb2bd06a749f11aa97302  libXpm-3.5.12.tar.bz2
e5e06eb14a608b58746bdd1c0bd7b8e3  libXaw-1.0.13.tar.bz2
07e01e046a0215574f36a3aacb148be0  libXfixes-5.0.3.tar.bz2
f7a218dcbf6f0848599c6c36fc65c51a  libXcomposite-0.4.4.tar.bz2
802179a76bded0b658f4e9ec5e1830a4  libXrender-0.9.10.tar.bz2
1e7c17afbbce83e2215917047c57d1b3  libXcursor-1.1.14.tar.bz2
0cf292de2a9fa2e9a939aefde68fd34f  libXdamage-1.1.4.tar.bz2
0920924c3a9ebc1265517bdd2f9fde50  libfontenc-1.1.3.tar.bz2
0d9f6dd9c23bf4bcbfb00504b566baf5  libXfont2-2.0.1.tar.bz2
331b3a2a3a1a78b5b44cfbd43f86fcfe  libXft-2.3.2.tar.bz2
1f0f2719c020655a60aee334ddd26d67  libXi-1.7.9.tar.bz2
9336dc46ae3bf5f81c247f7131461efd  libXinerama-1.1.3.tar.bz2
28e486f1d491b757173dd85ba34ee884  libXrandr-1.5.1.tar.bz2
45ef29206a6b58254c81bea28ec6c95f  libXres-1.0.7.tar.bz2
ef8c2c1d16a00bd95b9fdcef63b8a2ca  libXtst-1.2.3.tar.bz2
210b6ef30dda2256d54763136faa37b9  libXv-1.0.11.tar.bz2
4cbe1c1def7a5e1b0ed5fce8e512f4c6  libXvMC-1.0.10.tar.bz2
d7dd9b9df336b7dd4028b6b56542ff2c  libXxf86dga-1.1.4.tar.bz2
298b8fff82df17304dfdb5fe4066fe3a  libXxf86vm-1.1.4.tar.bz2
ba983eba5a9f05d152a0725b8e863151  libdmx-1.1.3.tar.bz2
d810ab17e24c1418dedf7207fb2841d4  libpciaccess-0.13.5.tar.bz2
4a4cfeaf24dab1b991903455d6d7d404  libxkbfile-1.0.9.tar.bz2
66662e76899112c0f99e22f2fc775a7e  libxshmfence-1.2.tar.bz2
EOF

cd ${CLFSSOURCES}/xc

mkdir lib &&
cd lib &&
grep -v '^#' ../lib-7.md5 | awk '{print $2}' | wget -i- -c \
    -B https://www.x.org/pub/individual/lib/ &&
md5sum -c ../lib-7.md5

PYTHONHOME="/usr/lib64/python3.6/"
PYTHONPATH="/usr/lib64/python3.6/"
USE_ARCH=32 PKG_CONFIG_PATH="${PKG_CONFIG_PATH32}"
CXX="g++ ${BUILD32}" CC="gcc ${BUILD32}

for package in $(grep -v '^#' ../lib-7.md5 | awk '{print $2}')
do
  packagedir=${package%.tar.bz2}
  tar -xf $package
  pushd $packagedir
  case $packagedir in
    libICE* )
      ./configure $XORG_CONFIG32 ICE_LIBS=-lpthread
    ;;

    libXfont2-[0-9]* )
      ./configure $XORG_CONFIG32 --disable-devel-docs
    ;;

    libXt-[0-9]* )
      ./configure $XORG_CONFIG32 \
                  --with-appdefaultdir=/etc/X11/app-defaults
    ;;

    * )
      ./configure $XORG_CONFIG32
    ;;
  esac
  make PREFIX=/usr LIBDIR=/usr/lib
  #make check 2>&1 | tee ../$packagedir-make_check.log
  #grep -A9 summary *make_check.log
  as_root make PREFIX=/usr LIBDIR=/usr/lib install
  checkBuiltPackage
  popd
  rm -rf $packagedir
  as_root /sbin/ldconfig
done

PYTHONHOME="/usr/lib64/python3.6/"
PYTHONPATH="/usr/lib64/python3.6/"
USE_ARCH=64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"
CXX="g++ ${BUILD64}" CC="gcc ${BUILD64}

cd ${CLFSSOURCES}/xc
cd lib

for package in $(grep -v '^#' ../lib-7.md5 | awk '{print $2}')
do
  packagedir=${package%.tar.bz2}
  tar -xf $package
  pushd $packagedir
  case $packagedir in
    libICE* )
      ./configure $XORG_CONFIG64 ICE_LIBS=-lpthread
    ;;

    libXfont2-[0-9]* )
      ./configure $XORG_CONFIG64 --disable-devel-docs
    ;;

    libXt-[0-9]* )
      ./configure $XORG_CONFIG64 \
                  --with-appdefaultdir=/etc/X11/app-defaults
    ;;

    * )
      ./configure $XORG_CONFIG64
    ;;
  esac
  make PREFIX=/usr LIBDIR=/usr/lib64
  #make check 2>&1 | tee ../$packagedir-make_check.log
  #grep -A9 summary *make_check.log
  as_root make PREFIX=/usr LIBDIR=/usr/lib64 install
  checkBuiltPackage
  popd
  rm -rf $packagedir
  as_root /sbin/ldconfig
done

cd ${CLFSSOURCES}/xc



