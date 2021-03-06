#!/bin/bash

function checkBuiltPackage() {
echo " "
echo "Make sure you are able to continue... [Y/N]"
while read -n1 -r -p "[Y/N]   " && [[ $REPLY != q ]]; do
  case $REPLY in
    Y) break 1;;
    N) echo "$EXIT"
       echo "Fix it!"
       exit 1;;
    *) echo " Try again. Type y or n";;
  esac
done
echo " "
}

#Building the final CLFS System
CLFS=/
CLFSSOURCES=/sources
MAKEFLAGS="-j$(nproc)"
BUILD32="-m32"
BUILD64="-m64"
CLFS_TARGET32="i686-pc-linux-gnu"
PKG_CONFIG_PATH=/usr/lib64/pkgconfig
PKG_CONFIG_PATH64=/usr/lib64/pkgconfig

export CLFS=/
export CLFSUSER=clfs
export CLFSSOURCES=/sources
export MAKEFLAGS="-j$(nproc)"
export BUILD32="-m32"
export BUILD64="-m64"
export CLFS_TARGET32="i686-pc-linux-gnu"
export PKG_CONFIG_PATH=/usr/lib64/pkgconfig
export PKG_CONFIG_PATH64=/usr/lib64/pkgconfig

sudo rm -rf ${CLFSSOURCES}/xc/xfce4

sudo mkdir -pv ${CLFSSOURCES}/xc/xfce4
cd ${CLFSSOURCES}/xc/xfce4

sudo chown -Rv overflyer ${CLFSSOURCES}/xc

#We will only do 64-bit builds in this script
#We compiled Xorg with 32-bit libraries
#That should suffice

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" 
USE_ARCH=64 
CXX="g++ ${BUILD64}" 
CC="gcc ${BUILD64}"

export PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" 
export USE_ARCH=64 
export CXX="g++ ${BUILD64}" 
export CC="gcc ${BUILD64}"

#PCRE (NOT PCRE2!!!)
wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.41.tar.bz2 -O \
  pcre-8.41.tar.bz2

mkdir pcre && tar xf pcre-*.tar.* -C pcre --strip-components 1
cd pcre

./configure --prefix=/usr                     \
            --docdir=/usr/share/doc/pcre-8.41 \
            --enable-unicode-properties       \
            --enable-pcre16                   \
            --enable-pcre32                   \
            --enable-pcregrep-libz            \
            --enable-pcregrep-libbz2          \
            --enable-pcretest-libreadline     \
            --disable-static                  \
            --libdir=/usr/lib64

make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install 
sudo mv -v /usr/lib64/libpcre.so.* /lib64 &&
sudo ln -sfv ../../../../lib64/$(readlink /usr/lib64/libpcre.so) /usr/lib64/libpcre.so
sudo ldconfig

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf pcre

#Glib
wget http://ftp.gnome.org/pub/gnome/sources/glib/2.52/glib-2.52.3.tar.xz -O \
  glib-2.52.3.tar.xz

mkdir glib && tar xf glib-*.tar.* -C glib --strip-components 1
cd glib

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
    --prefix=/usr \
    --with-pcre=system \
    --libdir=/usr/lib64

make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf glib

#libxfce4util
wget http://archive.xfce.org/src/xfce/libxfce4util/4.12/libxfce4util-4.12.1.tar.bz2 -O \
  libxfce4util-4.12.1.tar.bz2

mkdir libxfce4util && tar xf libxfce4util-*.tar.* -C libxfce4util --strip-components 1
cd libxfce4util

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
    --libdir=/usr/lib64 \
    --disable-gtk-doc

make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libxfce4util

#dbus
wget http://dbus.freedesktop.org/releases/dbus/dbus-1.10.22.tar.gz -O \
  dbus-1.10.22.tar.gz

mkdir dbus && tar xf dbus-*.tar.* -C dbus --strip-components 1
cd dbus

sudo groupadd -g 18 messagebus &&
sudo useradd -c "D-Bus Message Daemon User" -d /var/run/dbus \
        -u 18 -g messagebus -s /bin/false messagebus

./configure --prefix=/usr                        \
            --sysconfdir=/etc                    \
            --libdir=/usr/lib64                  \
            --localstatedir=/var                 \
            --disable-doxygen-docs               \
            --disable-xml-docs                   \
            --disable-static                     \
            --docdir=/usr/share/doc/dbus-1.10.20 \
            --with-console-auth-dir=/run/console \
            --with-system-pid-file=/run/dbus/pid \
            --with-system-socket=/run/dbus/system_bus_socket \
            --disable-systemd \
            --without-systemdsystemunitdir
            
make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install 

sudo mkdir /lib/lsb
sudo mkdir /lib64/lsb
sudo ln -sfv /etc/rc.d/init.d/functions /lib/lsb/init-functions
sudo ln -sfv /etc/rc.d/init.d/functions /lib64/lsb/init-functions

sudo sed -i 's/\/lib\/lsb\/init-functions/\/lib64\/lsb\/init-functions/' /etc/rc.d/init.d/*
sudo sed -i 's/loadproc/start_daemon/' /etc/rc.d/init.d/functions
sudo sed -i 's/load_msg_info/echo/' /etc/rc.d/init.d/functions

sudo mkdir /etc/dbus-1/
sudo mkdir /usr/share/dbus-1/
sudo mkdir /var/run/dbus
 
sudo dbus-uuidgen --ensure

sudo bash -c 'cat > /etc/dbus-1/session-local.conf << "EOF"
<!DOCTYPE busconfig PUBLIC
 "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig>
  <!-- Search for .service files in /usr/share -->
  <servicedir>/usr/share/dbus-1/services</servicedir>
</busconfig>
EOF'

cd ${CLFSSOURCES}/bootscripts
sudo make install-dbus

sudo sed -i 's/loadproc/start_daemon/' /etc/rc.d/init.d/dbus
sudo sed -i 's/load_msg_info/echo/' /etc/rc.d/init.d/dbus

sudo /etc/rc.d/init.d/dbus start

#More info ondbus:
#http://www.linuxfromscratch.org/hints/downloads/files/execute-session-scripts-using-kdm.txt

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf dbus

#dbus-glib
wget http://dbus.freedesktop.org/releases/dbus-glib/dbus-glib-0.108.tar.gz -O \
    dbus-glib-0.108.tar.gz

mkdir dbus-glib && tar xf dbus-glib-*.tar.* -C dbus-glib --strip-components 1
cd dbus-glib

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
            --sysconfdir=/etc \
            --libdir=/usr/lib64 \
            --disable-static \
            --disable-gtk-doc
            
make PREFIX=/usr LIBDIR=/usr/lib4
sudo make PREFIX=/usr LIBDIR=/usr/lib4 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf dbus-glib

#Xfconf
wget http://archive.xfce.org/src/xfce/xfconf/4.12/xfconf-4.12.1.tar.bz2 -O \
  xfconf-4.12.1.tar.bz2

mkdir xfconf && tar xf xfconf-*.tar.* -C xfconf --strip-components 1
cd xfconf

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
            --libdir=/usr/lib64 \
            --disable-static \
            --disable-gtk-doc
            
make PREFIX=/usr LIBDIR=/usr/lib4
sudo make PREFIX=/usr LIBDIR=/usr/lib4 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf xfconf

#desktop-file-utils
wget http://freedesktop.org/software/desktop-file-utils/releases/desktop-file-utils-0.23.tar.xz -O \
  desktop-file-utils-0.23.tar.xz

mkdir desktop-file-utils && tar xf desktop-file-utils-*.tar.* -C desktop-file-utils --strip-components 1
cd desktop-file-utils

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
    --prefix=/usr \
    --libdir=/usr/lib64

make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

sudo update-desktop-database /usr/share/applications

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf desktop-file-utils

#gobj-introspection
wget http://ftp.gnome.org/pub/gnome/sources/gobject-introspection/1.52/gobject-introspection-1.52.1.tar.xz -O \
gobject-introspection-1.52.1.tar.xz

mkdir gobject-introspection && tar xf gobject-introspection-*.tar.* -C gobject-introspection --strip-components 1
cd gobject-introspection

export PYTHON=/usr/bin/python2.7

PYTHON=/usr/bin/python2.7 \
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --disable-static \
     --enable-shared && 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" install

unset PYTHON

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf gobject-introspection

#at-spi2-core
wget http://ftp.gnome.org/pub/gnome/sources/at-spi2-core/2.24/at-spi2-core-2.24.1.tar.xz -O \
  at-spi2-core-2.24.1.tar.xz

mkdir atspi2core && tar xf at-spi2-core-*.tar.* -C atspi2core --strip-components 1
cd atspi2core

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --disable-static \
     --enable-shared \
     --sysconfdir=/etc

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf atspi2core

#ATK
wget http://ftp.gnome.org/pub/gnome/sources/atk/2.24/atk-2.24.0.tar.xz -O \
    atk-2.24.0.tar.xz

mkdir atk && tar xf atk-*.tar.* -C atk --strip-components 1
cd atk

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --disable-static \
     --enable-shared \
     --sysconfdir=/etc

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf atk

#at-spi2-atk
wget http://ftp.gnome.org/pub/gnome/sources/at-spi2-atk/2.24/at-spi2-atk-2.24.1.tar.xz -O \
  at-spi2-atk-2.24.1.tar.xz

mkdir atspi2atk && tar xf at-spi2-atk-*.tar.* -C atspi2atk --strip-components 1
cd atspi2atk

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --disable-static \
     --enable-shared \
     --sysconfdir=/etc

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf atspi2atk

#Cython
wget https://pypi.python.org/packages/10/d5/753d2cb5073a9f4329d1ffed1de30b0458821780af8fdd8ba1ad5adb6f62/Cython-0.26.tar.gz -O \
    Cython-0.26.tar.gz

mkdir cython && tar xf Cython-*.tar.* -C cython --strip-components 1
cd cython

python3 setup.py build
sudo python3 setup.py install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf cython

#yasm
wget http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz -O \
    yasm-1.3.0.tar.gz

mkdir yasm && tar xf yasm-*.tar.* -C yasm --strip-components 1
cd yasm

sed -i 's#) ytasm.*#)#' Makefile.in

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf yasm

#libjpeg-turbo
wget http://downloads.sourceforge.net/libjpeg-turbo/libjpeg-turbo-1.5.2.tar.gz -O \
    libjpeg-turbo-1.5.2.tar.gz

mkdir libjpeg-turbo && tar xf libjpeg-turbo-*.tar.* -C libjpeg-turbo --strip-components 1
cd libjpeg-turbo

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --mandir=/usr/share/man \
     --with-jpeg8            \
     --disable-static        \
     --docdir=/usr/share/doc/libjpeg-turbo-1.5.2

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install

sudo ldconfig

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libjpeg-turbo

#libpng installed by bootloader script clfs_6b1....sh
#libepoxy installed by Xorg script

#libtiff
wget http://download.osgeo.org/libtiff/tiff-4.0.8.tar.gz -O \
    tiff-4.0.8.tar.gz

mkdir libtiff && tar xf tiff-*.tar.* -C libtiff --strip-components 1
cd libtiff

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --disable-static

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libtiff

#ICU
wget http://download.icu-project.org/files/icu4c/59.1/icu4c-59_1-src.tgz -O \
    icu4c-59_1-src.tgz

mkdir icu && tar xf icu*.tgz -C icu --strip-components 1
cd icu
cd source

#this patch is probably ONLY for glibx 2.26
#it might cause icu to fail building for another glibc version
sed -i 's/xlocale/locale/' i18n/digitlst.cpp

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --disable-static

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf icu

#harfbuzz, freetype2 and which were installed by Xorg scripts
#Pixman and libpng needed by  Cairo are also already installed by UEFI-bootloader script and Xorg script, respectively

#Cairo
wget http://cairographics.org/releases/cairo-1.14.10.tar.xz -O \
    cairo-1.14.10.tar.xz

mkdir cairo && tar xf cairo-*.tar.* -C cairo --strip-components 1
cd cairo

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --disable-static \
     --enable-tee

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf cairo

#Nevertheless I seem to need to rebuild
#harfbuzz, fontconfig and freetype
#Pango is complaining that it wont find any backends

cd ${CLFSSOURCES}

#freetype 64-bit
mkdir freetype && tar xf freetype-*.tar.* -C freetype --strip-components 1
cd freetype

sed -ri "s:.*(AUX_MODULES.*valid):\1:" modules.cfg

sed -r "s:.*(#.*SUBPIXEL_RENDERING) .*:\1:" \
    -i include/freetype/config/ftoption.h 

sed -i -r 's:.*(#.*BYTE.*) .*:\1:' include/freetype/config/ftoption.h

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
USE_ARCH=64 \
CC="gcc ${BUILD64}" ./configure \
--prefix=/usr \
--disable-static \
--libdir=/usr/lib64

PREFIX=/usr LIBDIR=/usr/lib64 make
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

sudo mv -v /usr/bin/freetype-config{,-64}
sudo ln -sf multiarch_wrapper /usr/bin/freetype-config
sudo install -v -m755 -d /usr/share/doc/freetype-2.4.12
sudo cp -v -R docs/* /usr/share/doc/freetype-2.4.12

sudo install -v -m755 -d /usr/share/doc/freetype-2.8
sudo cp -v -R docs/*     /usr/share/doc/freetype-2.8

cd ${CLFSSOURCES} 
#checkBuiltPackage
sudo rm -rf freetype

#harfbuzz 64-bit
mkdir harfbuzz && tar xf harfbuzz-*.tar.* -C harfbuzz --strip-components 1
cd harfbuzz

LIBDIR=/usr/lib64 USE_ARCH=64 PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
CXX="g++ ${BUILD64}" CC="gcc ${BUILD64}" \
./configure --prefix=/usr --libdir=/usr/lib64
PREFIX=/usr LIBDIR=/usr/lib64 make 
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES} 
#checkBuiltPackage
sudo rm -rf harfbuzz

cd ${CLFSSOURCES} 
#checkBuiltPackage
sudo rm -rf freetype

#freeype 64-bit
mkdir freetype && tar xf freetype-*.tar.* -C freetype --strip-components 1
cd freetype

sed -ri "s:.*(AUX_MODULES.*valid):\1:" modules.cfg

sed -r "s:.*(#.*SUBPIXEL_RENDERING) .*:\1:" \
    -i include/freetype/config/ftoption.h 

sed -i -r 's:.*(#.*BYTE.*) .*:\1:' include/freetype/config/ftoption.h

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" \
USE_ARCH=64 \
CC="gcc ${BUILD64}" ./configure \
--prefix=/usr \
--disable-static \
--libdir=/usr/lib64

PREFIX=/usr LIBDIR=/usr/lib64 make
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

sudo mv -v /usr/bin/freetype-config{,-64}
sudo ln -sf multiarch_wrapper /usr/bin/freetype-config
sudo install -v -m755 -d /usr/share/doc/freetype-2.4.12
sudo cp -v -R docs/* /usr/share/doc/freetype-2.4.12

sudo install -v -m755 -d /usr/share/doc/freetype-2.8
sudo cp -v -R docs/*     /usr/share/doc/freetype-2.8

cd ${CLFSSOURCES} 
#checkBuiltPackage
sudo rm -rf freetype

cd ${CLFSSOURCES}/xc/xfce4

#Pango
wget http://ftp.gnome.org/pub/gnome/sources/pango/1.40/pango-1.40.6.tar.xz -O \
    pango-1.40.6.tar.xz

mkdir pango && tar xf pango-*.tar.* -C pango --strip-components 1
cd pango

ln -sv ${XORG_PREFIX}/share/fonts /usr/share/

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --disable-static \
     --sysconfdir=/etc

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

sudo ldconfig

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf pango

#hicolor-icon-theme
wget http://icon-theme.freedesktop.org/releases/hicolor-icon-theme-0.15.tar.xz -O \
    hicolor-icon-theme-0.15.tar.xz

mkdir hicoloricontheme && tar xf hicolor-icon-theme-*.tar.* -C hicoloricontheme --strip-components 1
cd hicoloricontheme

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 

sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf hicoloricontheme

#adwaita-icon-theme
wget http://ftp.gnome.org/pub/gnome/sources/adwaita-icon-theme/3.24/adwaita-icon-theme-3.24.0.tar.xz -O \
    adwaita-icon-theme-3.24.0.tar.xz

mkdir adwaiticontheme && tar xf adwaita-icon-theme-*.tar.* -C adwaiticontheme --strip-components 1
cd adwaiticontheme

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
     --libdir=/usr/lib64 

sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf adwaiticontheme

#gdk-pixbuf
wget http://ftp.gnome.org/pub/gnome/sources/gdk-pixbuf/2.36/gdk-pixbuf-2.36.6.tar.xz -O \
    gdk-pixbuf-2.36.6.tar.xz

mkdir gdk-pixbuf && tar xf gdk-pixbuf-*.tar.* -C gdk-pixbuf --strip-components 1
cd gdk-pixbuf

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --with-x11

make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64

#make -k check
#checkBuiltPackage

sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install

sudo ldconfig

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf gdk-pixbuf

#GTK2
wget http://ftp.gnome.org/pub/gnome/sources/gtk+/2.24/gtk+-2.24.31.tar.xz -O \
    gtk+-2.24.31.tar.xz

mkdir gtk2 && tar xf gtk+-2*.tar.* -C gtk2 --strip-components 1
cd gtk2

sed -e 's#l \(gtk-.*\).sgml#& -o \1#' \
    -i docs/{faq,tutorial}/Makefile.in      

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
  PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
  --sysconfdir=/etc --libdir=/usr/lib64

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cat > ~/.gtkrc-2.0 << "EOF"
include "/usr/share/themes/Glider/gtk-2.0/gtkrc"
gtk-icon-theme-name = "hicolor"
EOF

sudo bash -c 'cat > /etc/gtk-2.0/gtkrc << "EOF"
include "/usr/share/themes/Clearlooks/gtk-2.0/gtkrc"
gtk-icon-theme-name = "elementary"
EOF'

sudo ldconfig

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf gtk2

#gtk3
wget http://ftp.gnome.org/pub/gnome/sources/gtk+/3.22/gtk+-3.22.16.tar.xz -O \
    gtk+-3.22.16.tar.xz

mkdir gtk3 && tar xf gtk+-3*.tar.* -C gtk3 --strip-components 1
cd gtk3

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --sysconfdir=/etc         \
     --enable-broadway-backend \
     --enable-x11-backend      \
     --disable-wayland-backend 

make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64

make -k check
checkBuiltPackage

sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install

mkdir -vp ~/.config/gtk-3.0
cat > ~/.config/gtk-3.0/settings.ini << "EOF"
[Settings]
gtk-theme-name = Adwaita
gtk-icon-theme-name = oxygen
gtk-font-name = DejaVu Sans 12
gtk-cursor-theme-size = 18
gtk-toolbar-style = GTK_TOOLBAR_BOTH_HORIZ
gtk-xft-antialias = 1
gtk-xft-hinting = 1
gtk-xft-hintstyle = hintslight
gtk-xft-rgba = rgb
gtk-cursor-theme-name = Adwaita
EOF

sudo ldconfig

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf gtk3

#startup-notification
wget http://www.freedesktop.org/software/startup-notification/releases/startup-notification-0.12.tar.gz -O \
    startup-notification-0.12.tar.gz

mkdir startup-notification && tar xf startup-notification-*.tar.* -C startup-notification --strip-components 1
cd startup-notification

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-static 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

sudo install -v -m644 -D doc/startup-notification.txt \
    /usr/share/doc/startup-notification-0.12/startup-notification.txt

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf startup-notification

#Test::Needs (optional for Perl Module Tests)

#URI
wget https://www.cpan.org/authors/id/E/ET/ETHER/URI-1.72.tar.gz -O \
  URI-1.72.tar.gz

mkdir URI && tar xf URI-*.tar.* -C URI --strip-components 1
cd URI

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" perl Makefile.PL 
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make prefix=/usr libdir=/usr/lib64
#make test
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" prefix=/usr libdir=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf URI

##HTML-Tagset
#http://search.cpan.org/CPAN/authors/id/P/PE/PETDANCE/HTML-Tagset-3.20.tar.gz -O \
#  HTML-Tagset-3.20.tar.gz
#
#mkdir HTML-Tagset && tar xf HTML-Tagset-*.tar.* -C HTML-Tagset --strip-components 1
#cd HTML-Tagset
#
#PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" perl Makefile.PL 
#PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make prefix=/usr libdir=/usr/lib64
##make test
#sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" prefix=/usr libdir=/usr/lib64 install
#
#cd ${CLFSSOURCES}/xc/xfce4
#checkBuiltPackage
#sudo rm -rf HTML-Tagset
#
##HTML::Parser
#wget https://www.cpan.org/authors/id/G/GA/GAAS/HTML-Parser-3.72.tar.gz -O \
#  HTML-Parser-3.72.tar.gz
# 
#mkdir HTML-Parser && tar xf HTML-Parser-*.tar.* -C HTML-Parser --strip-components 1
#cd HTML-Parser
#
#PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" perl Makefile.PL 
#PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make prefix=/usr libdir=/usr/lib64
##make test
#sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" prefix=/usr libdir=/usr/lib64 install
#
#cd ${CLFSSOURCES}/xc/xfce4
#checkBuiltPackage
#sudo rm -rf HTML-Parser
#
#Encode::Locale
#URI
#HTML::Parser
#HTTP::Date
#IO::HTML
#LWP:MediaTypes
#HTTP::Message
#HTML::Form
#HTTP::Cookies
#HTTP::Negotiate
#Net::HTTP
#WWW::RobotRules
#HTTP::Daemon
#File::Listing
#Test::RequiresInternet
#Test::Fatal
#libwww-perl

#Insert optional GLADE dependency here
#wget http://ftp.gnome.org/pub/GNOME/sources/glade3/3.8/ for gtk2
#wget http://ftp.gnome.org/pub/GNOME/sources/glade/3.20/ for gtk3
#https://glade.gnome.org/

#libxfce4ui
wget http://archive.xfce.org/src/xfce/libxfce4ui/4.12/libxfce4ui-4.12.1.tar.bz2 -O \
  libxfce4ui-4.12.1.tar.bz2

mkdir libxfce4ui && tar xf libxfce4ui-*.tar.* -C libxfce4ui --strip-components 1
cd libxfce4ui

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
     --sysconfdir=/etc \
     --libdir=/usr/lib64 \
     --disable-gtk-doc

make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install 

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libxfce4ui

#Exo
wget http://archive.xfce.org/src/xfce/exo/0.10/exo-0.10.7.tar.bz2 -O \
  exo-0.10.7.tar.bz2

mkdir exo && tar xf exo-*.tar.* -C exo --strip-components 1
cd exo

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
     --sysconfdir=/etc \
     --libdir=/usr/lib64 \
     --disable-gtk-doc

make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install 

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf exo

#Garcon
wget http://archive.xfce.org/src/xfce/garcon/0.6/garcon-0.6.1.tar.bz2 -O \
  garcon-0.6.1.tar.bz2

mkdir garcon && tar xf garcon-*.tar.* -C garcon --strip-components 1
cd garcon

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
     --sysconfdir=/etc \
     --libdir=/usr/lib64 \
     --disable-gtk-doc

make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install 

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf garcon

#gtk-xfce-engine
wget http://archive.xfce.org/src/xfce/gtk-xfce-engine/3.2/gtk-xfce-engine-3.2.0.tar.bz2 -O \
gtk-xfce-engine-3.2.0.tar.bz2

mkdir gtk-xfce-engine && tar xf gtk-xfce-engine-*.tar.* -C gtk-xfce-engine --strip-components 1
cd gtk-xfce-engine

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
     --sysconfdir=/etc \
     --libdir=/usr/lib64 \
     --disable-gtk-doc

make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf gtk-xfce-engine

#libwnk
wget http://ftp.gnome.org/pub/gnome/sources/libwnck/2.30/libwnck-2.30.7.tar.xz -O \
    libwnck-2.30.7.tar.xz

mkdir libwnck && tar xf libwnck-*.tar.* -C libwnck --strip-components 1
cd libwnck

CC="gcc ${BUILD64}"   CXX="g++ ${BUILD64}" USE_ARCH=64    \
  PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr    \
  --libdir=/usr/lib64 --sysconfdir=/etc --disable-static \
  --program-suffix=-1
  
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make GETTEXT_PACKAGE=libwnck-1 LIBDIR=/usr/lib64 PREFIX=/usr
sudo make GETTEXT_PACKAGE=libwnck-1 LIBDIR=/usr/lib64 PREFIX=/usr install
  
cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libwnck

#iso-codes 
wget https://pkg-isocodes.alioth.debian.org/downloads/iso-codes-3.75.tar.xz -O \
	iso-codes-3.75.tar.xz 
mkdir iso-codes && tar xf iso-codes-*.tar.* -C iso-codes --strip-components 1 
cd iso-codes 

sed -i '/^LN_S/s/s/sfvn/' */Makefile 

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \ 
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
	--libdir=/usr/lib64
 
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr 

sudo make LIBDIR=/usr/lib64 PREFIX=/usr install 

cd ${CLFSSOURCES}/xc/xfce4 
checkBuiltPackage 
sudo rm -rf

#libxklavier
wget http://pkgs.fedoraproject.org/repo/pkgs/libxklavier/libxklavier-5.4.tar.bz2/13af74dcb6011ecedf1e3ed122bd31fa/libxklavier-5.4.tar.bz2 -O \
    libxklavier-5.4.tar.bz2

mkdir libxklavier && tar xf libxklavier-*.tar.* -C libxklavier --strip-components 1
cd libxklavier
    
CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr --libdir=/usr/lib64 \
    --disable-static

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libxklavier

#xfce4-panel
wget http://archive.xfce.org/src/xfce/xfce4-panel/4.12/xfce4-panel-4.12.1.tar.bz2 -O \
  xfce4-panel-4.12.1.tar.bz2
  
mkdir xfce4-panel && tar xf xfce4-panel-*.tar.* -C xfce4-panel --strip-components 1
cd xfce4-panel

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64    \
  PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr    \
  --libdir=/usr/lib64 --sysconfdir=/etc --disable-static \
  --disable-gtk-doc --enable-gtk3
  
make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf xfce4-panel

#libxml2 WITH ITS PYTHON 2 MODULE
wget http://xmlsoft.org/sources/libxml2-2.9.4.tar.gz -O \
    libxml2-2.9.4.tar.gz

#Download testsuite. WE NEED IT to build the Python module!
wget http://www.w3.org/XML/Test/xmlts20130923.tar.gz -O \
    xmlts20130923.tar.gz

mkdir libxml2 && tar xf libxml2-*.tar.* -C libxml2 --strip-components 1
cd libxml2

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --disable-static \
   --with-history   \
   --libdir=/usr/lib64 \
   --with-python=/usr/bin/python2.7 \
   --with-icu \
   --with-threads

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} make PREFIX=/usr LIBDIR=/usr/lib64

tar xf ../xmlts20130923.tar.gz
make check > check.log
grep -E '^Total|expected' check.log
checkBuiltPackage

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install 

cd ${CLFSSOURCES}/xc/xfce4
sudo updatedb
sudo bash -c 'locate libxml2 | grep python2.7'
echo "Did locate libxml | grep python2.7 find the libxml2 python2 modules?"
echo ""

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libxml2

#libxml2 WITH ITS PYTHON 3 MODULE
mkdir libxml2 && tar xf libxml2-*.tar.* -C libxml2 --strip-components 1
cd libxml2

#run this to build Python3 module
#Python2 module would be the default
#We try not to use Python2 in CLFS multib!
sed -i '/_PyVerify_fd/,+1d' python/types.c

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --disable-static \
   --with-history   \
   --libdir=/usr/lib64 \
   --with-python=/usr/bin/python3.6 \
   --with-icu \
   --with-threads

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} make PREFIX=/usr LIBDIR=/usr/lib64

tar xf ../xmlts20130923.tar.gz
make check > check.log
grep -E '^Total|expected' check.log
checkBuiltPackage

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install 

cd ${CLFSSOURCES}/xc/xfce4
sudo updatedb
sudo bash -c 'locate libxml2 | grep python3.6/'
echo "Did locate libxml | grep python3.6 find the libxml2 python3 modules?"
echo ""

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libxml2

#libcroco
wget http://ftp.gnome.org/pub/gnome/sources/libcroco/0.6/libcroco-0.6.12.tar.xz -O \
    libcroco-0.6.12.tar.xz

mkdir libcroco && tar xf libcroco-*.tar.* -C libcroco --strip-components 1
cd libcroco

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-static

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libcroco

#Vala
wget http://ftp.gnome.org/pub/gnome/sources/vala/0.36/vala-0.36.4.tar.xz -O \
    vala-0.36.4.tar.xz

mkdir vala && tar xf vala-*.tar.* -C vala --strip-components 1
cd vala

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-static 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf vala

#librsvg
wget http://ftp.gnome.org/pub/gnome/sources/librsvg/2.40/librsvg-2.40.17.tar.xz -O \
    librsvg-2.40.17.tar.xz

mkdir librsvg && tar xf librsvg-*.tar.* -C librsvg --strip-components 1
cd librsvg

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-static \
   --enable-vala

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf librsvg

#xfce4-xkb-plugin
wget http://archive.xfce.org/src/panel-plugins/xfce4-xkb-plugin/0.7/xfce4-xkb-plugin-0.7.1.tar.bz2 -O \
  xfce4-xkb-plugin-0.7.1.tar.bz2

mkdir xfce4-xkb-plugin && tar xf xfce4-xkb-plugin-*.tar.* -C xfce4-xkb-plugin --strip-components 1
cd xfce4-xkb-plugin

sed -e 's|xfce4/panel-plugins|xfce4/panel/plugins|' \
    -i panel-plugin/{Makefile.in,xkb-plugin.desktop.in.in} 

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64    \
  PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr  \
  --libdir=/usr/lib64 --libexecdir=/usr/lib64 --disable-static \
  --disable-debug
  
make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf xfce4-xkb-plugin

#XML::NamespaceSupport
wget http://search.cpan.org/CPAN/authors/id/P/PE/PERIGRIN/XML-NamespaceSupport-1.12.tar.gz -O \
	XML-NamespaceSupport-1.12.tar.gz

mkdir XML-NamespaceSupport && tar xf XML-NamespaceSupport-*.tar.* -C XML-NamespaceSupport --strip-components 1
cd XML-NamespaceSupport

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" perl Makefile.PL
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make prefix=/usr libdir=/usr/lib64
#make test
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" prefix=/usr libdir=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf XML-NamespaceSupport

#XML::SAX::Base
wget http://search.cpan.org/CPAN/authors/id/G/GR/GRANTM/XML-SAX-Base-1.09.tar.gz -O \
	XML-SAX-Base-1.09.tar.gz

mkdir XML-SAX-Base && tar xf XML-SAX-Base-*.tar.* -C XML-SAX-Base --strip-components 1
cd XML-SAX-Base

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" perl Makefile.PL
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make prefix=/usr libdir=/usr/lib64
#make test
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" prefix=/usr libdir=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf XML-SAX-Base

#XML::SAX
wget http://www.cpan.org/modules/by-module/XML/XML-SAX-0.99.tar.gz -O \
	XML-SAX-0.99.tar.gz

mkdir XML-SAX && tar xf XML-SAX-*.tar.* -C XML-SAX --strip-components 1
cd XML-SAX

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" perl Makefile.PL
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make prefix=/usr libdir=/usr/lib64
#make test
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" prefix=/usr libdir=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf XML-SAX

#XML::SAX::Expat
wget http://search.cpan.org/CPAN/authors/id/B/BJ/BJOERN/XML-SAX-Expat-0.51.tar.gz -O \
	XML-SAX-Expat-0.51.tar.gz

mkdir XML-SAX-Expat && tar xf XML-SAX-Expat-*.tar.* -C XML-SAX-Expat --strip-components 1
cd XML-SAX-Expat

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" perl Makefile.PL
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make prefix=/usr libdir=/usr/lib64
#make test
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" prefix=/usr libdir=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf XML-SAX-Expat

#XML::LibXML
wget http://search.cpan.org/CPAN/authors/id/S/SH/SHLOMIF/XML-LibXML-2.0129.tar.gz -O \
	XML-LibXML-2.0129.tar.gz

mkdir XML-LibXML && tar xf XML-LibXML-*.tar.* -C XML-LibXML --strip-components 1
cd XML-LibXML

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" perl Makefile.PL
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make prefix=/usr libdir=/usr/lib64
#make test
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" prefix=/usr libdir=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf XML-LibXML

#XML::Simple
wget http://search.cpan.org/CPAN/authors/id/G/GR/GRANTM/XML-Simple-2.24.tar.gz -O \
    XML-Simple-2.24.tar.gz

mkdir XML-Simple && tar xf XML-Simple-*.tar.* -C XML-Simple --strip-components 1
cd XML-Simple

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" perl Makefile.PL
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make prefix=/usr libdir=/usr/lib64
#make test
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" prefix=/usr libdir=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf XML-Simple

#icon-naming-utils
wget http://tango.freedesktop.org/releases/icon-naming-utils-0.8.90.tar.bz2 -O \
	icon-naming-utils-0.8.90.tar.bz2

mkdir icon-naming-utils && tar xf icon-naming-utils-*.tar.* -C icon-naming-utils --strip-components 1
cd icon-naming-utils

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64    \
  PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr  \
  --libdir=/usr/lib64
 
make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf icon-naming-utils

#gnome-icon-theme
wget http://ftp.gnome.org/pub/gnome/sources/gnome-icon-theme/3.12/gnome-icon-theme-3.12.0.tar.xz -O \
    gnome-icon-theme-3.12.0.tar.xz

mkdir gnome-icon-theme && tar xf gnome-icon-theme-*.tar.* -C gnome-icon-theme --strip-components 1
cd gnome-icon-theme

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 

sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf gnome-icon-theme

#libudev

#libgudev
wget http://ftp.gnome.org/pub/gnome/sources/libgudev/231/libgudev-231.tar.xz -O \
    libgudev-231.tar.xz

mkdir libgudev && tar xf libgudev-*.tar.* -C libgudev --strip-components 1
cd libgudev

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-static \
   --disable-umockdev

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libgudev

#Vala
wget http://ftp.gnome.org/pub/gnome/sources/vala/0.36/vala-0.36.4.tar.xz -O \
    vala-0.36.4.tar.xz

mkdir vala && tar xf vala-*.tar.* -C vala --strip-components 1
cd vala

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-static 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf vala

#libgpg-error
wget ftp://ftp.gnupg.org/gcrypt/libgpg-error/libgpg-error-1.27.tar.bz2 -O \
    libgpg-error-1.27.tar.bz2
    
mkdir libgpgerror && tar xf libgpg-error-*.tar.* -C libgpgerror --strip-components 1
cd libgpgerror

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr --libdir=/usr/lib64
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"  make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
rm -r libgpgerror

#libgcrypt
wget ftp://ftp.gnupg.org/gcrypt/libgcrypt/libgcrypt-1.7.8.tar.bz2 -O \
    libgcrypt-1.7.8.tar.bz2
    
mkdir libgcrypt && tar xf libgcrypt-*.tar.* -C libgcrypt --strip-components 1
cd libgcrypt

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr --libdir=/usr/lib64
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"  make LIBDIR=/usr/lib64 PREFIX=/usr
make check
checkBuiltPackage

sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
rm -r libgcrypt

#libtasn1
wget http://ftp.gnu.org/gnu/libtasn1/libtasn1-4.12.tar.gz -O \
    libtasn1-4.12.tar.gz

mkdir libtasn1 && tar xf libtasn1-*.tar.* -C libtasn1 --strip-components 1
cd libtasn1

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
    --libdir=/usr/lib64 \
    --disable-static
    
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"  make LIBDIR=/usr/lib64 PREFIX=/usr
make check
checkBuiltPackage

sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
rm -r libtasn1

#p11-kit
wget https://github.com/p11-glue/p11-kit/releases/download/0.23.7/p11-kit-0.23.7.tar.gz -O \
    p11-kit-0.23.7.tar.gz
    
mkdir p11-kit && tar xf p11-kit-*.tar.* -C p11-kit --strip-components 1
cd p11-kit

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
    --libdir=/usr/lib64 \
    --disable-static \
    --sysconfdir=/etc \
    --with-trust-paths=/etc/pki/anchor
    
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"  make LIBDIR=/usr/lib64 PREFIX=/usr
make check
checkBuiltPackage

sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
rm -r p11-kit



#libsecret
wget http://ftp.gnome.org/pub/gnome/sources/libsecret/0.18/libsecret-0.18.5.tar.xz -O \
    libsecret-0.18.5.tar.xz

mkdir libsecret && tar xf libsecret-*.tar.* -C libsecret --strip-components 1
cd libsecret

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
  PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
  --libdir=/usr/lib64 --disable-gtk-doc --disable-manpages

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libsecret

#libwebp
wget http://downloads.webmproject.org/releases/webp/libwebp-0.6.0.tar.gz -O \
    libwebp-0.6.0.tar.gz

mkdir libwebp && tar xf libwebp-*.tar.* -C libwebp --strip-components 1
cd libwebp

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
  PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
  --libdir=/usr/lib64 \
  --enable-libwebpmux     \
  --enable-libwebpdemux   \
  --enable-libwebpdecoder \
  --enable-libwebpextras  \
  --enable-swap-16bit-csp \

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libwebp

#sqlite
wget http://sqlite.org/2017/sqlite-autoconf-3190300.tar.gz -O \
    sqlite-autoconf-3190300.tar.gz

mkdir sqlite-autoconf && tar xf sqlite-autoconf-*.tar.* -C sqlite-autoconf --strip-components 1
cd sqlite-autoconf

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
            --disable-static        \
            --libdir=/usr/lib64     \
            CFLAGS="-g -O2 -DSQLITE_ENABLE_FTS3=1 \
            -DSQLITE_ENABLE_COLUMN_METADATA=1     \
            -DSQLITE_ENABLE_UNLOCK_NOTIFY=1       \
            -DSQLITE_SECURE_DELETE=1              \
            -DSQLITE_ENABLE_DBSTAT_VTAB=1" &&

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf sqlite-autoconf

#nettle
wget https://ftp.gnu.org/gnu/nettle/nettle-3.3.tar.gz -O \
    nettle-3.3.tar.gz

mkdir nettle && tar xf nettle-*.tar.* -C nettle --strip-components 1
cd nettle

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
   --libdir=/usr/lib64 --disable-static 
   
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
make check
checkBuiltPackage

sudo make LIBDIR=/usr/lib64 PREFIX=/usr install
sudo chmod   -v   755 /usr/lib64/lib{hogweed,nettle}.so
sudo install -v -m755 -d /usr/share/doc/nettle-3.3
sudo install -v -m644 nettle.html /usr/share/doc/nettle-3.3

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf nettle

#libunistring
wget https://ftp.gnu.org/gnu/libunistring/libunistring-0.9.7.tar.xz -O \
	libunistring-0.9.7.tar.xz

mkdir libunistring && tar xf libunistring-*.tar.* -C libunistring --strip-components 1
cd libunistring

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
   --libdir=/usr/lib64 --disable-static \
   --docdir=/usr/share/doc/libunistring-0.9.7

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libunistring

#libidn2
wget https://ftp.gnu.org/gnu/libidn/libidn2-2.0.4.tar.gz -O \
	libidn2-2.0.4.tar.gz

mkdir libidn2 && tar xf libidn2-*.tar.* -C libidn2 --strip-components 1
cd libidn2

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
   --libdir=/usr/lib64 --disable-static 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install


cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libidn2

#libidn2
wget https://ftp.gnu.org/gnu/libidn/libidn-1.33.tar.gz -O \
    libidn-1.33.tar.gz

mkdir libidn && tar xf libidn-*.tar.* -C libidn --strip-components 1
cd libidn

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
   --libdir=/usr/lib64 --disable-static 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install


cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libidn

#p11-kit
wget https://github.com/p11-glue/p11-kit/releases/download/0.23.7/p11-kit-0.23.7.tar.gz -O \
    p11-kit-0.23.7.tar.gz
    
mkdir p11-kit && tar xf p11-kit-*.tar.* -C p11-kit --strip-components 1
cd p11-kit

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
    --libdir=/usr/lib64 \
    --disable-static \
    --sysconfdir=/etc \
    --with-trust-paths=/etc/pki/anchor
    
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"  make LIBDIR=/usr/lib64 PREFIX=/usr
make check
checkBuiltPackage

sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
rm -r p11-kit

#GnuTLS
wget https://www.gnupg.org/ftp/gcrypt/gnutls/v3.5/gnutls-3.5.14.tar.xz -O \
    gnutls-3.5.14.tar.xz
    
mkdir gnutls && tar xf gnutls-*.tar.* -C gnutls --strip-components 1
cd gnutls

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
   --libdir=/usr/lib64 --disable-static \
   --with-default-trust-store-pkcs11="pkcs11:" \
   --with-default-trust-store-file=/etc/ssl/ca-bundle.crt \
   --disable-gtk-doc \
   --enable-openssl-compatibility \
   --with-included-unistring
   
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
make check
checkBuiltPackage

sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf gnutls

#glib-networking
wget ftp://ftp.gnome.org/pub/gnome/sources/glib-networking/2.50/glib-networking-2.50.0.tar.xz -O \
    glib-networking-2.50.0.tar.xz

mkdir glibnet && tar xf glib-networking-*.tar.* -C glibnet --strip-components 1
cd glibnet

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
   --libdir=/usr/lib64 --disable-static \
   --without-ca-certificates 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
make -k check 
checkBuiltPackage

sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
rm -rf glibnet

#libnotify
wget http://ftp.gnome.org/pub/gnome/sources/libnotify/0.7/libnotify-0.7.7.tar.xz -O \
    libnotify-0.7.7.tar.xz

mkdir libnotify && tar xf libnotify-*.tar.* -C libnotify --strip-components 1
cd libnotify

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
   --libdir=/usr/lib64 --disable-static 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libnotify

#libsoup
wget http://ftp.gnome.org/pub/gnome/sources/libsoup/2.58/libsoup-2.58.1.tar.xz -O \
    libsoup-2.58.1.tar.xz

mkdir libsoup && tar xf libsoup-*.tar.* -C libsoup --strip-components 1
cd libsoup

CC="gcc ${BUILD64}" \
  CXX="g++ ${BUILD64}" USE_ARCH=64 \
   PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
   --libdir=/usr/lib64 --disable-static 

sudo ln -sfv /usr/bin/python3.6 /usr/bin/python

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
make check 
checkBuiltPackage

sudo make LIBDIR=/usr/lib64 PREFIX=/usr install
sudo unlink /usr/bin/python
sudo ldconfig

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libsoup

#libxslt
wget http://xmlsoft.org/sources/libxslt-1.1.31.tar.gz -O \
    libxslt-1.1.31.tar.gz 

mkdir libxslt && tar xf libxslt-*.tar.* -C libxslt --strip-components 1
cd libxslt

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --disable-static \
   --libdir=/usr/lib64 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

sudo ldconfig

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libxslt

#GCR
wget http://ftp.gnome.org/pub/gnome/sources/gcr/3.20/gcr-3.20.0.tar.xz -O \
    gcr-3.20.0.tar.xz
    
mkdir gcr && tar xf gcr-*.tar.* -C gcr --strip-components 1
cd gcr

sed -i -r 's:"(/desktop):"/org/gnome\1:' schema/*.xml

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
    --libdir=/usr/lib64 \
    --disable-static \
    --sysconfdir=/etc
 
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
make -k check
checkBuiltPackage

sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf gcr

#Gvfs
wget http://ftp.gnome.org/pub/gnome/sources/gvfs/1.32/gvfs-1.32.1.tar.xz -O \
	gvfs-1.32.1.tar.xz 

#You need to recompile udev with this patch in order
#For Gvfs to support gphoto2
wget https://sourceforge.net/p/gphoto/patches/_discuss/thread/9180a667/9902/attachment/libgphoto2.udev-136.patch -O \
	libgphoto2.udev-136.patch

mkdir gvfs && tar xf gvfs-*.tar.* -C gvfs --strip-components 1
cd gvfs

LD_LIB_PATH="/usr/lib64" LIBRARY_PATH="/usr/lib64" CPPFLAGS="-I/usr/include" \
LD_LIBRARY_PATH="/usr/lib64" CC="gcc ${BUILD64} -L/usr/lib64 -lacl" \
CXX="g++ ${BUILD64} -lacl" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
    --libdir=/usr/lib64 \
    --disable-static    \
    --sysconfdir=/etc    \
    --disable-gtk-doc \
    --disable-gtk-doc-pdf \
    --disable-gtk-doc-html \
    --disable-libsystemd-login \
    --disable-admin \
    --disable-gphoto2 \
    --disable-documentation
    
sudo ln -sfv /usr/lib64/libacl.so /lib64/
sudo ln -sfv /usr/lib64/libattr.so /lib64/
    
LD_LIB_PATH="/usr/lib64" LIBRARY_PATH="/usr/lib64" CPPFLAGS="-I/usr/include" \
LD_LIBRARY_PATH="/usr/lib64" CC="gcc ${BUILD64} -L/usr/lib64 -lacl" \
CXX="g++ ${BUILD64} -lacl" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf gvfs

#NSPR
wget https://ftp.mozilla.org/pub/mozilla.org/nspr/releases/v4.15/src/nspr-4.15.tar.gz -O \
    nspr-4.15.tar.gz

mkdir nspr && tar xf nspr-*.tar.* -C nspr --strip-components 1
cd nspr

cd nspr                                                     &&
sed -ri 's#^(RELEASE_BINS =).*#\1#' pr/src/misc/Makefile.in &&
sed -i 's#$(LIBRARY) ##'            config/rules.mk         &&

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --with-mozilla \
   --with-pthreads \
   $([ $(uname -m) = x86_64 ] && echo --enable-64bit)

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage

echo " "
echo "checking if /usr/include/pratom.h was installed..."
ls /usr/include | grep pratom.h
echo "... should be shown in output one line above. Mozjs 17.0.0 will fail otherwise."

sudo rm -rf nspr

#NSS
wget https://archive.mozilla.org/pub/security/nss/releases/NSS_3_33_RTM/src/nss-3.33.tar.gz -O \
    nss-3.33.tar.gz
    
wget http://www.linuxfromscratch.org/patches/blfs/svn/nss-3.33-standalone-1.patch -O \
    NSS-3.33-standalone-1.patch
    
mkdir nss && tar xf nss-*.tar.* -C nss --strip-components 1
cd nss

patch -Np1 -i ../NSS-3.33-standalone-1.patch 
cd nss

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} make -j1 BUILD_OPT=1 \
  NSPR_INCLUDE_DIR=/usr/include/nspr  \
  USE_SYSTEM_ZLIB=1                   \
  ZLIB_LIBS=-lz                       \
  NSS_ENABLE_WERROR=0                 \
  LIBDIR=/usr/lib64                   \
  PREFIX=/usr                         \
  $([ $(uname -m) = x86_64 ] && echo USE_64=1) \
  $([ -f /usr/include/sqlite3.h ] && echo NSS_USE_SYSTEM_SQLITE=1)
  
cd ../dist

sudo install -v -m755 Linux*/lib/*.so              /usr/lib64           
sudo install -v -m644 Linux*/lib/{*.chk,libcrmf.a} /usr/lib64            

sudo install -v -m755 -d                           /usr/include/nss      
sudo cp -v -RL {public,private}/nss/*              /usr/include/nss      
sudo chmod -v 644                                  /usr/include/nss/*    

sudo install -v -m755 Linux*/bin/{certutil,nss-config,pk12util} /usr/bin 

sudo install -v -m644 Linux*/lib/pkgconfig/nss.pc  /usr/lib64/pkgconfig

if [ -e /usr/lib64/libp11-kit.so ]; then
  sudo readlink /usr/lib64/libnssckbi.so ||  sudo rm -v /usr/lib64/libnssckbi.so
  sudo ln -sfv ./pkcs11/p11-kit-trust.so /usr/lib64/libnssckbi.so
fi

sh ${CLFSSOURCES}/make-ca.sh-* --force

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf nss

#js17
wget wget http://ftp.mozilla.org/pub/mozilla.org/js/mozjs17.0.0.tar.gz -O \
  mozjs17.0.0.tar.gz

mkdir mozjs && tar xf mozjs*.tar.* -C mozjs --strip-components 1
cd mozjs
cd js/src

sed -i 's/(defined\((@TEMPLATE_FILE)\))/\1/' config/milestone.pl

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr --libdir=/usr/lib64 \
  --enable-readline --enable-threadsafe \
  --with-system-ffi --with-system-nspr  

#Iso C++ can't compare pointer to Integer
#First element of array is seen as pointer
#So to make it a real value I just ficed it
#by derefferencing the pointer and compare THAT to '\0' (NULL)
sed -i 's/value\[0\] == /\*value\[0\] == /' shell/jsoptparse.cpp

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

sudo find /usr/include/js-17.0/            \
     /usr/lib64/libmozjs-17.0.a         \
     /usr/lib64/pkgconfig/mozjs-17.0.pc \
     -type f -exec chmod -v 644 {} \;

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf mozjs

#polkit 113
wget http://www.freedesktop.org/software/polkit/releases/polkit-0.113.tar.gz -O \
  polkit-0.113.tar.gz
  
mkdir polkit && tar xf polkit-*.tar.* -C polkit --strip-components 1
cd polkit

sudo mkdir /etc/polkit-1
sudo groupadd -fg 27 polkitd 
sudo useradd -c "PolicyKit Daemon Owner" -d /etc/polkit-1 -u 27 \
        -g polkitd -s /bin/false polkitd

echo " "
echo "Were polkitd group and user created successfully?"

checkBuiltPackage

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
            --sysconfdir=/etc    \
            --libdir=/usr/lib64  \
            --localstatedir=/var \
            --disable-static     \
            --disable-man-pages  \
            --disable-gtk-doc    \
            --with-pam           \
            --enable-systemd-logind=no 

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

sudo chown root:root /usr/lib/polkit-1/polkit-agent-helper-1
sudo chown root:root /usr/bin/pkexec
sudo chmod 4755 /usr/lib/polkit-1/polkit-agent-helper-1
sudo chmod 4755 /usr/bin/pkexec
sudo chown -Rv polkitd /etc/polkit-1/rules.d
sudo chown -Rv polkitd /usr/share/polkit-1/rules.d
sudo chmod 700 /etc/polkit-1/rules.d
sudo chmod 700 /usr/share/polkit-1/rules.d

sudo bash -c 'cat > /etc/pam.d/polkit-1 << "EOF"
# Begin /etc/pam.d/polkit-1
auth     include        system-auth
account  include        system-account
password include        system-password
session  include        system-session
# End /etc/pam.d/polkit-1
EOF'

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf polkit

#polkit-gnome
wget http://ftp.gnome.org/pub/gnome/sources/polkit-gnome/0.105/polkit-gnome-0.105.tar.xz -O \
	polkit-gnome-0.105.tar.xz

mkdir polkit-gnome && tar xf polkit-gnome-*.tar.* -C polkit-gnome --strip-components 1
cd polkit-gnome	

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr --libdir=/usr/lib64
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"  make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

sudo mkdir -p /etc/xdg/autostart &&
sudo bash -c 'cat > /etc/xdg/autostart/polkit-gnome-authentication-agent-1.desktop << "EOF"
[Desktop Entry]
Name=PolicyKit Authentication Agent
Comment=PolicyKit Authentication Agent
Exec=/usr/libexec/polkit-gnome-authentication-agent-1
Terminal=false
Type=Application
Categories=
NoDisplay=true
OnlyShowIn=GNOME;XFCE;Unity;
AutostartCondition=GNOME3 unless-session gnome
EOF'

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf gnome-polkit

#libatasmart
wget http://0pointer.de/public/libatasmart-0.19.tar.xz -O \
    libatasmart-0.19.tar.xz

mkdir libatasmart && tar xf libatasmart-*.tar.* -C libatasmart --strip-components 1
cd libatasmart

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr\
    --libdir=/usr/lib64 \
    --disable-static

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce
checkBuiltPackage
sudo rm -rf libatasmart

#libbytesize
wget https://github.com/storaged-project/libbytesize/archive/libbytesize-0.11.tar.gz -O \
    libbytesize-0.11.tar.gz

mkdir libbytesize && tar xf libbytesize-*.tar.* -C libbytesize --strip-components 1
cd libbytesize

sh autogen.sh

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr\
    --libdir=/usr/lib64 \
    --disable-static

sed -i 's/docs/#docs/' Makefile*

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libbytesize

#LVM2
wget ftp://sources.redhat.com/pub/lvm2/releases/LVM2.2.02.171.tgz -O \
	LVM2.2.02.171.tgz

mkdir LVM2 && tar xf LVM2*.tgz -C LVM2 --strip-components 1
cd LVM2

SAVEPATH=$PATH PATH=$PATH:/sbin:/usr/sbin \
CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr\
	--libdir=/usr/lib64 \
	--disable-static    \
    	--exec-prefix=      \
    	--enable-applib     \
    	--enable-cmdlib     \
    	--enable-pkgconfig  \
    	--enable-udev_sync
    
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

PATH=$SAVEPATH                 
unset SAVEPATH

export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

sudo make -C tools install_dmsetup_dynamic 
sudo make -C udev  install                 
sudo make -C libdm install

sudo mv /usr/lib/pkgconfig/devmapper.pc ${PKG_CONFIG_PATH64}/
sudo sudo mv /usr/lib/libdevmapper.so /usr/lib64/

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf LVM2

#parted
wget http://ftp.gnu.org/gnu/parted/parted-3.2.tar.xz -O \
    parted-3.2.tar.xz

#wget http://www.linuxfromscratch.org/patches/blfs/svn/parted-3.2-devmapper-1.patch -O \
#   Parted-3.2-devmapper-1.patch

mkdir parted && tar xf parted-*.tar.* -C parted --strip-components 1
cd parted

#patch -Np1 -i ../Parted-3.2-devmapper-1.patch

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr\
    --libdir=/usr/lib64 \
    --disable-static

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf parted

#dmraid
wget http://people.redhat.com/~heinzm/sw/dmraid/src/dmraid-current.tar.bz2 -O \
    dmraid-current.tar.bz2

mkdir dmraid && tar xf dmraid-*.tar.* -C dmraid --strip-components 3
cd dmraid

sudo cp -rv include/dmraid /usr/inlude/

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf dmraid

#mdadm
wget http://www.kernel.org/pub/linux/utils/raid/mdadm/mdadm-4.0.tar.xz -O \
    mdadm-4.0.tar.xz

mkdir mdadm && tar xf mdadm-*.tar.* -C mdadm --strip-components 1
cd mdadm

#Fix for GCC 7.1
sed 's@-Werror@@' -i Makefile

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf mdadm

#LZO
wget http://www.oberhumer.com/opensource/lzo/download/lzo-2.10.tar.gz -O \
    lzo-2.10.tar.gz

mkdir lzo && tar xf lzo-*.tar.* -C lzo --strip-components 1
cd lzo

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr\
    --libdir=/usr/lib64 \
    --disable-static \
    --enable-shared \
    --docdir=/usr/share/doc/lzo-2.10

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf lzo

#btrfs-progs
wget https://www.kernel.org/pub/linux/kernel/people/kdave/btrfs-progs/btrfs-progs-v4.12.tar.xz -O \
    btrfs-progs-v4.12.tar.xz

mkdir btrfs-progs && tar xf btrfs-progs-*.tar.* -C btrfs-progs --strip-components 1
cd btrfs-progs

sed -i '1,100 s/\.gz//g' Documentation/Makefile.in

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr\
    --libdir=/lib64 \
    --disable-static \
    --disable-documentation

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/lib64

mv tests/fuzz-tests/003-multi-check-unmounted/test.sh{,.broken}    &&
mv tests/fuzz-tests/004-simple-dump-tree/test.sh{,.broken}         &&
mv tests/fuzz-tests/007-simple-super-recover/test.sh{,.broken}     &&
mv tests/fuzz-tests/009-simple-zero-log/test.sh{,.broken}          &&
mv tests/misc-tests/019-receive-clones-on-munted-subvol/test.sh{,.broken}

#pushd tests
#   sudo ./fsck-tests.sh
#   sudo ./mkfs-tests.sh
#   sudo ./convert-tests.sh
#   sudo ./misc-tests.sh
#   sudo ./cli-tests.sh
#   sudo ./fuzz-tests.sh
#popd

sudo make PREFIX=/usr LIBDIR=/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf btrfs-progs

#libassuan
wget ftp://ftp.gnupg.org/gcrypt/libassuan/libassuan-2.4.3.tar.bz2 -O \
    libassuan-2.4.3.tar.bz2
    
mkdir libassuan && tar xf libassuan-*.tar.* -C libassuan --strip-components 1
cd libassuan

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
    --libdir=/usr/lib64 \
    --disable-static
    
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"  make LIBDIR=/usr/lib64 PREFIX=/usr
make check
checkBuiltPackage

sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -r libassuan

#GPGME
wget ftp://ftp.gnupg.org/gcrypt/gpgme/gpgme-1.9.0.tar.bz2 -O \
	gpgme-1.9.0.tar.bz2

mkdir gpgme && tar xf gpgme-*.tar.* -C gpgme --strip-components 1
cd gpgme

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr\
    --libdir=/usr/lib64 \
	--disable-static

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf gpgme

#SWIG
wget http://downloads.sourceforge.net/swig/swig-3.0.12.tar.gz -O \
	swig-3.0.12.tar.gz

mkdir swig && tar xf swig-*.tar.* -C swig --strip-components 1
cd swig

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr\
    --libdir=/usr/lib64 \
	--disable-static \
	--without-clisp   \
    --without-maximum-compile-warnings

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

sudo cp -rv  /usr/lib/python2.7/ /usr/lib64/

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
rm -rf swig

#cryptsetup
wget https://www.kernel.org/pub/linux/utils/cryptsetup/v1.7/cryptsetup-1.7.5.tar.xz -O \
	cryptsetup-1.7.5.tar.xz

mkdir cryptsetup && tar xf cryptsetup-*.tar.* -C cryptsetup --strip-components 1
cd cryptsetup

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr\
    --libdir=/usr/lib64 \
	--disable-static

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf cryptsetup

#volume_key
wget https://releases.pagure.org/volume_key/volume_key-0.3.9.tar.xz -O \
	volume_key-0.3.9.tar.xz

mkdir volume_key && tar xf volume_key-*.tar.* -C volume_key --strip-components 1
cd volume_key

export PYTHON=/usr/bin/python3.6
sudo ln -sfv /usr/bin/python3.6 /usr/bin/python

sed -i 's/$(PYTHON_VERSION)/3.6/' Makefile*
sed -i 's/\/lib\/python3.6/\/lib64\/python3.6/' Makefile*
sed -i 's/\/lib6464\/python3.6/\/lib64\/python3.6/' Makefile*
sed -i 's/<Python.h>/\"\/usr\/include\/python3.6m\/Python.h\"/' python/volume_key_wrap.c
sed -i '/config.h/d' lib/libvolume_key.h

autoreconf -fiv

PYTHON=/usr/bin/python3.6 \
CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr\
	--libdir=/usr/lib64 \
	--disable-static

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

sudo unlink /usr/bin/python
unset PYTHON

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf volume_key

#libblockdev
wget https://github.com/storaged-project/libblockdev/releases/download/2.13-1/libblockdev-2.13.tar.gz -O \
    libblockdev-2.13.tar.gz

mkdir libblockdev && tar xf libblockdev-*.tar.* -C libblockdev --strip-components 1
cd libblockdev

sh autogen.sh

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr\
    --libdir=/usr/lib64 \
    --disable-static \
    --without-dm 

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sed -i 's/docs/#docs/' Makefile*

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libblockdev

#UDisks
wget https://github.com/storaged-project/udisks/releases/download/udisks-2.7.3/udisks-2.7.3.tar.bz2 -O \
	udisks-2.7.3.tar.bz2

mkdir udisks && tar xf udisks-*.tar.* -C udisks --strip-components 1
cd udisks	

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
    --libdir=/usr/lib64	\
    --libexecdir=/usr/lib64 \
    --disable-static    \
    --sysconfdir=/etc	\
    --localstatedir=/var \
    --disable-gtk-doc	\
    --disable-gtk-doc-pdf \
    --disable-gtk-doc-html \
    --disable-man 	\
    --enable-shared 	\
    --enable-btrfs 	\
    --enable-lvm2 	\
    --enable-lvmcache	\
    --enable-polkit	\
    --disable-tests \
	--disable-logind \
	--with-systemdsystemunitdir=no \
	--with-udevdir=/lib64/udev

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf udisks

#libexif
wget http://downloads.sourceforge.net/libexif/libexif-0.6.21.tar.bz2 -O \
	libexif-0.6.21.tar.bz2

mkdir libexif && tar xf libexif-*.tar.* -C libexif --strip-components 1
cd libexif

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr\
    --libdir=/usr/lib64 \
    --with-doc-dir=/usr/share/doc/libexif-0.6.21 \
	--disable-static

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libexif

#gstreamer
wget https://gstreamer.freedesktop.org/src/gstreamer/gstreamer-1.12.1.tar.xz -O \
    gstreamer-1.12.1.tar.xz

mkdir gstreamer && tar xf gstreamer-*.tar.* -C gstreamer --strip-components 1
cd gstreamer

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-static \
   --with-package-name="GStreamer 1.12.1 BLFS" \
   --with-package-origin="http://www.linuxfromscratch.org/blfs/view/svn/" 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo rm -rf /usr/bin/gst-* /usr/{lib,libexec}/gstreamer-1.0

make check
checkBuiltPackage

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

sudo ldconfig

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf gstreamer

#gst-plugins-base
wget https://gstreamer.freedesktop.org/src/gst-plugins-base/gst-plugins-base-1.12.1.tar.xz -O \
    gst-plugins-base-1.12.1.tar.xz

mkdir gstplgbase && tar xf gst-plugins-base-*.tar.* -C gstplgbase --strip-components 1
cd gstplgbase

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-static \
   --with-package-name="GStreamer 1.12.1 BLFS" \
   --with-package-origin="http://www.linuxfromscratch.org/blfs/view/svn/" 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64

make check
checkBuiltPackage

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf gstplgbase

#gst-plugins-good
wget https://gstreamer.freedesktop.org/src/gst-plugins-good/gst-plugins-good-1.12.1.tar.xz -O \
    gst-plugins-good-1.12.1.tar.xz

mkdir gstplggood && tar xf gst-plugins-good-*.tar.* -C gstplggood --strip-components 1
cd gstplggood

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-static \
   --with-package-name="GStreamer 1.12.1 BLFS" \
   --with-package-origin="http://www.linuxfromscratch.org/blfs/view/svn/" 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64

make check
checkBuiltPackage

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf gstplggood

#yasm
wget http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz -O \
    yasm-1.3.0.tar.gz

mkdir yasm && tar xf yasm-*.tar.* -C yasm --strip-components 1
cd yasm

sed -i 's#) ytasm.*#)#' Makefile.in

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf yasm

#libjpeg-turbo
wget http://downloads.sourceforge.net/libjpeg-turbo/libjpeg-turbo-1.5.2.tar.gz -O \
    libjpeg-turbo-1.5.2.tar.gz

mkdir libjpeg-turbo && tar xf libjpeg-turbo-*.tar.* -C libjpeg-turbo --strip-components 1
cd libjpeg-turbo

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --mandir=/usr/share/man \
     --with-jpeg8            \
     --disable-static        \
     --docdir=/usr/share/doc/libjpeg-turbo-1.5.2

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install

sudo ldconfig

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libjpeg-turbo

#libpng installed by bootloader script clfs_6b1....sh
#libepoxy installed by Xorg script

#libtiff
wget http://download.osgeo.org/libtiff/tiff-4.0.8.tar.gz -O \
    tiff-4.0.8.tar.gz

mkdir libtiff && tar xf tiff-*.tar.* -C libtiff --strip-components 1
cd libtiff

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --disable-static

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libtiff

#libgsf
wget http://ftp.gnome.org/pub/gnome/sources/libgsf/1.14/libgsf-1.14.41.tar.xz -O \
  libgsf-1.14.41.tar.xz

mkdir libgsf && tar xf libgsf-*.tar.* -C libgsf --strip-components 1
cd libgsf

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
     --libdir=/usr/lib64 \
     --disable-static

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libgsf

#littleCMS2
wget http://downloads.sourceforge.net/lcms/lcms2-2.8.tar.gz -O \
    lcms2-2.8.tar.gz

mkdir lcms2 && tar xf lcms2-*.tar.* -C lcms2 --strip-components 1
cd lcms2

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-static \

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf lcms2

#OpenJPEG
wget http://downloads.sourceforge.net/openjpeg.mirror/openjpeg-1.5.2.tar.gz -O \
    openjpeg-1.5.2.tar.gz
    
mkdir openjpeg && tar xf openjpeg-*.tar.* -C openjpeg --strip-components 1
cd openjpeg

autoreconf -f -i

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
    --libdir=/usr/lib64 \
    --sysconfdir=/etc \
    --disable-static

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf openjpeg
#Cairo
wget http://cairographics.org/releases/cairo-1.14.10.tar.xz -O \
    cairo-1.14.10.tar.xz

mkdir cairo && tar xf cairo-*.tar.* -C cairo --strip-components 1
cd cairo

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --disable-static \
     --enable-tee

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf cairo

#NSPR
wget https://ftp.mozilla.org/pub/mozilla.org/nspr/releases/v4.15/src/nspr-4.15.tar.gz -O \
    nspr-4.15.tar.gz

mkdir nspr && tar xf nspr-*.tar.* -C nspr --strip-components 1
cd nspr

cd nspr                                                     &&
sed -ri 's#^(RELEASE_BINS =).*#\1#' pr/src/misc/Makefile.in &&
sed -i 's#$(LIBRARY) ##'            config/rules.mk         &&

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --with-mozilla \
   --with-pthreads \
   $([ $(uname -m) = x86_64 ] && echo --enable-64bit)

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
echo " "
echo "checking if /usr/include/pratom.h was installed..."
ls /usr/include | grep pratom.h
echo "... should be shown in output one line above. Mozjs 17.0.0 will fail otherwise."
sudo rm -rf nspr

#libtasn1
wget http://ftp.gnu.org/gnu/libtasn1/libtasn1-4.12.tar.gz -O \
    libtasn1-4.12.tar.gz

mkdir libtasn1 && tar xf libtasn1-*.tar.* -C libtasn1 --strip-components 1
cd libtasn1

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
    --libdir=/usr/lib64 \
    --disable-static
    
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"  make LIBDIR=/usr/lib64 PREFIX=/usr
make check
checkBuiltPackage

sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
rm -r libtasn1

#poppler-glib 
wget http://poppler.freedesktop.org/poppler-0.56.0.tar.xz -O \
    poppler-0.56.0.tar.xz
    
wget http://poppler.freedesktop.org/poppler-data-0.4.7.tar.gz -O \
    Poppler-data-0.4.7.tar.gz

mkdir poppler && tar xf poppler-*.tar.* -C poppler --strip-components 1
cd poppler

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
    --libdir=/usr/lib64 \
    --sysconfdir=/etc \
    --disable-static            \
    --enable-build-type=release \
    --enable-cmyk               \
    --enable-xpdf-headers       \
    --with-testdatadir=$PWD/testfile

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

mkdir poppler-data
tar -xf ../Poppler-data-*.tar.gz -C poppler-data --strip-components 1 
cd poppler-data

sudo make LIBDIR=/usr/lib64 prefix=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf poppler

#volume_key
wget https://releases.pagure.org/volume_key/volume_key-0.3.9.tar.xz -O \
    volume_key-0.3.9.tar.xz

mkdir volume_key && tar xf volume_key-*.tar.* -C volume_key --strip-components 1
cd volume_key

export PYTHON=/usr/bin/python3.6
sudo ln -sfv /usr/bin/python3.6 /usr/bin/python

sed -i 's/$(PYTHON_VERSION)/3.6/' Makefile*
sed -i 's/\/lib\/python3.6/\/lib64\/python3.6/' Makefile*
sed -i 's/\/lib6464\/python3.6/\/lib64\/python3.6/' Makefile*
sed -i 's/<Python.h>/\"\/usr\/include\/python3.6m\/Python.h\"/' python/volume_key_wrap.c
sed -i '/config.h/d' lib/libvolume_key.h

autoreconf -fiv

PYTHON=/usr/bin/python3.6 \
CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr\
    --libdir=/usr/lib64 \
    --disable-static

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

sudo unlink /usr/bin/python
unset PYTHON

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf volume_key

#sgml-common
wget http://anduin.linuxfromscratch.org/BLFS/sgml-common/sgml-common-0.6.3.tgz -O \
    sgml-common-0.6.3.tgz

wget http://www.linuxfromscratch.org/patches/blfs/svn/sgml-common-0.6.3-manpage-1.patch -O \
    Sgml-common-0.6.3-manpage-1.patch 

mkdir sgml-common && tar xf sgml-common-*.tgz -C sgml-common --strip-components 1
cd sgml-common

patch -Np1 -i ../Sgml-common-0.6.3-manpage-1.patch

autoreconf -f -i

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --sysconfdir=/etc

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 docdir=/usr/share/doc install

sudo install-catalog --remove /etc/sgml/sgml-ent.cat \
    /usr/share/sgml/sgml-iso-entities-8879.1986/catalog &&

sudo install-catalog --remove /etc/sgml/sgml-docbook.cat \
    /etc/sgml/sgml-ent.cat

sudo install-catalog --add /etc/sgml/sgml-ent.cat \
    /usr/share/sgml/sgml-iso-entities-8879.1986/catalog &&

sudo install-catalog --add /etc/sgml/sgml-docbook.cat \
    /etc/sgml/sgml-ent.cat

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf sgml-common

#Unzip
wget http://downloads.sourceforge.net/infozip/unzip60.tar.gz -O \
    unzip60.tar.gz

mkdir unzip && tar xf unzip*.tar.* -C unzip --strip-components 1
cd unzip

sed -i 's/CC = cc#/CC = gcc#/' unix/Makefile

CC="gcc ${BUILD64}" \
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make prefix=/usr libdir=/usr/lib64 -f unix/Makefile generic
sudo make prefix=/usr libdir=/usr/lib64 -f unix/Makefile install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf unzip

sudo chown -Rv overflyer ${CLFSSOURCES}

#docbook-xml
wget http://www.docbook.org/xml/4.5/docbook-xml-4.5.zip -O \
    docbook-xml-4.5.zip

unzip docbook-xml-*.zip

sudo install -v -d -m755 /usr/share/xml/docbook/xml-dtd-4.5
sudo install -v -d -m755 /etc/xml
sudo chown -R root:root .
sudo cp -v -af catalog.xml docbook.cat *.dtd ent/ *.mod /usr/share/xml/docbook/xml-dtd-4.5

if [ ! -e /etc/xml/docbook ]; then
    sudo xmlcatalog --noout --create /etc/xml/docbook
fi &&
sudo xmlcatalog --noout --add "public" \
    "-//OASIS//DTD DocBook XML V4.5//EN" \
    "http://www.oasis-open.org/docbook/xml/4.5/docbookx.dtd" \
    /etc/xml/docbook &&
sudo xmlcatalog --noout --add "public" \
    "-//OASIS//DTD DocBook XML CALS Table Model V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/calstblx.dtd" \
    /etc/xml/docbook &&
sudo xmlcatalog --noout --add "public" \
    "-//OASIS//DTD XML Exchange Table Model 19990315//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/soextblx.dtd" \
    /etc/xml/docbook &&
sudo xmlcatalog --noout --add "public" \
    "-//OASIS//ELEMENTS DocBook XML Information Pool V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbpoolx.mod" \
    /etc/xml/docbook &&
sudo xmlcatalog --noout --add "public" \
    "-//OASIS//ELEMENTS DocBook XML Document Hierarchy V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbhierx.mod" \
    /etc/xml/docbook &&
sudo xmlcatalog --noout --add "public" \
    "-//OASIS//ELEMENTS DocBook XML HTML Tables V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/htmltblx.mod" \
    /etc/xml/docbook &&
sudo xmlcatalog --noout --add "public" \
    "-//OASIS//ENTITIES DocBook XML Notations V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbnotnx.mod" \
    /etc/xml/docbook &&
sudo xmlcatalog --noout --add "public" \
    "-//OASIS//ENTITIES DocBook XML Character Entities V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbcentx.mod" \
    /etc/xml/docbook &&
sudo xmlcatalog --noout --add "public" \
    "-//OASIS//ENTITIES DocBook XML Additional General Entities V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbgenent.mod" \
    /etc/xml/docbook &&
sudo xmlcatalog --noout --add "rewriteSystem" \
    "http://www.oasis-open.org/docbook/xml/4.5" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5" \
    /etc/xml/docbook &&
sudo xmlcatalog --noout --add "rewriteURI" \
    "http://www.oasis-open.org/docbook/xml/4.5" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5" \
    /etc/xml/docbook

if [ ! -e /etc/xml/catalog ]; then
    sudo xmlcatalog --noout --create /etc/xml/catalog
fi &&
sudo xmlcatalog --noout --add "delegatePublic" \
    "-//OASIS//ENTITIES DocBook XML" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog &&
sudo xmlcatalog --noout --add "delegatePublic" \
    "-//OASIS//DTD DocBook XML" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog &&
sudo xmlcatalog --noout --add "delegateSystem" \
    "http://www.oasis-open.org/docbook/" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog &&
sudo xmlcatalog --noout --add "delegateURI" \
    "http://www.oasis-open.org/docbook/" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog

for DTDVERSION in 4.1.2 4.2 4.3 4.4
do
  sudo xmlcatalog --noout --add "public" \
    "-//OASIS//DTD DocBook XML V$DTDVERSION//EN" \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION/docbookx.dtd" \
    /etc/xml/docbook
  sudo xmlcatalog --noout --add "rewriteSystem" \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5" \
    /etc/xml/docbook
  sudo xmlcatalog --noout --add "rewriteURI" \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5" \
    /etc/xml/docbook
  sudo xmlcatalog --noout --add "delegateSystem" \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION/" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog
  sudo xmlcatalog --noout --add "delegateURI" \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION/" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog
done

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage

sudo chown -Rv overflyer ${CLFSSOURCES}

#docbook-xsl
wget http://downloads.sourceforge.net/docbook/docbook-xsl-1.79.1.tar.bz2 -O \
    docbook-xsl-1.79.1.tar.bz2

mkdir docbook-xsl && tar xf docbook-xsl-*.tar.* -C docbook-xsl --strip-components 1
cd docbook-xsl

sudo install -v -m755 -d /usr/share/xml/docbook/xsl-stylesheets-1.79.1 &&

sudo cp -v -R VERSION assembly common eclipse epub epub3 extensions fo  \
         highlighting html htmlhelp images javahelp lib manpages params  \
         profiling roundtrip slides template tests tools webhelp website \
         xhtml xhtml-1_1 xhtml5                                          \
         /usr/share/xml/docbook/xsl-stylesheets-1.79.1 

sudo ln -s VERSION /usr/share/xml/docbook/xsl-stylesheets-1.79.1/VERSION.xsl &&

sudo install -v -m644 -D README \
                    /usr/share/doc/docbook-xsl-1.79.1/README.txt &&
sudo install -v -m644    RELEASE-NOTES* NEWS* \
                    /usr/share/doc/docbook-xsl-1.79.1

sudo xmlcatalog --noout --add "rewriteSystem" \
           "http://docbook.sourceforge.net/release/xsl/<version>" \
           "/usr/share/xml/docbook/xsl-stylesheets-<version>" \
    /etc/xml/catalog &&

sudo xmlcatalog --noout --add "rewriteURI" \
           "http://docbook.sourceforge.net/release/xsl/<version>" \
           "/usr/share/xml/docbook/xsl-stylesheets-<version>" \
    /etc/xml/catalog

sudo cp ${CLFSSOURCES}/docbook-xml-xsl.tar.* .
sudo mkdir xml 
sudo tar xf docbook-xml-xsl.tar.* -C xml --strip-components 1
sudo cp -rv xml /etc/

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
#echo " "
#echo "For me xmlcatalog --noout --add was failing"
#echo "With \"add command failed\""
#echo "I cheated and copied /etc/xml/* over to clfs from my host distro"
#echo " "
sudo rm -rf docbook-xsl

sudo chown -Rv overflyer ${CLFSSOURCES}

#itstool
wget http://files.itstool.org/itstool/itstool-2.0.2.tar.bz2 -O \
    itstool-2.0.2.tar.bz2

mkdir itstool && tar xf itstool-*.tar.* -C itstool --strip-components 1
cd itstool

sed -i 's/python \- \&/python3.6 \- \&/' configure

export PYTHON=/usr/bin/python3.6
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr 
sudo make PREFIX=/usr install

unset PYTHON

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
rm -rf itstool

#gtk-doc
wget http://ftp.gnome.org/pub/gnome/sources/gtk-doc/1.25/gtk-doc-1.25.tar.xz -O \
    gtk-doc-1.25.tar.xz

mkdir gtk-doc && tar xf gtk-doc-*.tar.* -C gtk-doc --strip-components 1
cd gtk-doc

PYTHON=/usr/bin/python2.7 \
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
    --libdir=/usr/lib64 --enable-shared --disable-static \
    --with-xml-catalog=/etc/xml/catalog --sysconfdir=/etc --datarootdir=/usr/share
    
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf gtk-doc

#tumbler
wget http://archive.xfce.org/src/xfce/tumbler/0.2/tumbler-0.2.0.tar.bz2 -O \
	tumbler-0.2.0.tar.bz2

mkdir tumbler && tar xf tumbler-*.tar.* -C tumbler --strip-components 1
cd tumbler

sed -i 's/<ft2build.h>/\"\/usr\/include\/freetype2\/ft2build.h\"/' plugins/font-thumbnailer/font-thumbnailer.c

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
    --libdir=/usr/lib64 
    
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"  make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf tumbler

#Thunar
wget http://archive.xfce.org/src/xfce/thunar/1.6/Thunar-1.6.12.tar.bz2 -O \
	Thunar-1.6.12.tar.bz2
	
mkdir Thunar && tar xf Thunar-*.tar.* -C Thunar --strip-components 1
cd Thunar

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
    --libdir=/usr/lib64 --sysconfdir=/etc \
    --docdir=/usr/share/doc/Thunar-1.6.12
    
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"  make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf Thunar

#thunar-volman
wget http://archive.xfce.org/src/xfce/thunar-volman/0.8/thunar-volman-0.8.1.tar.bz2 -O \
	thunar-volman-0.8.1.tar.bz2

mkdir thunar-volman && tar xf thunar-volman-*.tar.* -C thunar-volman --strip-components 1
cd thunar-volman

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
    --libdir=/usr/lib64 
    
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"  make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf thunar-volman

#xfce-appfinder
wget http://archive.xfce.org/src/xfce/xfce4-appfinder/4.12/xfce4-appfinder-4.12.0.tar.bz2 -O \
	xfce4-appfinder-4.12.0.tar.bz2

mkdir xfce4-appfinder && tar xf xfce4-appfinder-*.tar.* -C xfce4-appfinder --strip-components 1
cd xfce4-appfinder

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
    --libdir=/usr/lib64 
    
PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"  make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf xfce4-appfinder

#libusb
wget https://github.com//libusb/libusb/releases/download/v1.0.21/libusb-1.0.21.tar.bz2 -O \
    libusb-1.0.21.tar.bz2

mkdir libusb && tar xf libusb-*.tar.* -C libusb --strip-components 1
cd libusb

sed -i "s/^PROJECT_LOGO/#&/" doc/doxygen.cfg.in

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-static 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make -j1 PREFIX=/usr LIBDIR=/usr/lib64
sudo make -j1 PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libusb

#libgusb
wget http://people.freedesktop.org/~hughsient/releases/libgusb-0.2.10.tar.xz -O \
    libgusb-0.2.10.tar.xz

mkdir libgusb && tar xf libgusb-*.tar.* -C libgusb --strip-components 1
cd libgusb

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-static \
   --disable-gtk-doc \ 
   --disable-gtk-doc-html \ 
   --disable-gtk-doc-pdf  

sed -i 's/docs/#docs/' Makefile*

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libgusb

#UPower
wget https://upower.freedesktop.org/releases/upower-0.99.6.tar.xz -O \
	upower-0.99.6.tar.xz

mkdir upower && tar xf upower-*.tar.* -C upower --strip-components 1
cd upower

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
    --libdir=/usr/lib64 \
    --sysconfdir=/etc    \
    --localstatedir=/var \
    --enable-deprecated  \
    --disable-static \
    --disable-gtk-doc

sed -i 's/doc/#doc/' Makefile*

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}"  make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf upower

#libatasmart
wget http://0pointer.de/public/libatasmart-0.19.tar.xz -O \
	libatasmart-0.19.tar.xz

mkdir libatasmart && tar xf libatasmart-*.tar.* -C libatasmart --strip-components 1
cd libatasmart

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr\
    --libdir=/usr/lib64 \
    --with-doc-dir=/usr/share/doc/libexif-0.6.21 \
	--disable-static

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libatasmart

#parted
wget http://ftp.gnu.org/gnu/parted/parted-3.2.tar.xz -O \
	parted-3.2.tar.xz

#wget http://www.linuxfromscratch.org/patches/blfs/svn/parted-3.2-devmapper-1.patch -O \
#	Parted-3.2-devmapper-1.patch

mkdir parted && tar xf parted-*.tar.* -C parted --strip-components 1
cd parted

#patch -Np1 -i ../Parted-3.2-devmapper-1.patch

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr\
	--libdir=/usr/lib64 \
	--disable-static

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf parted

#dmraid
wget http://people.redhat.com/~heinzm/sw/dmraid/src/dmraid-current.tar.bz2 -O \
	dmraid-current.tar.bz2

mkdir dmraid && tar xf dmraid-*.tar.* -C dmraid --strip-components 3
cd dmraid

sudo cp -rv include/dmraid /usr/inlude/

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf dmraid

#mdadm
wget http://www.kernel.org/pub/linux/utils/raid/mdadm/mdadm-4.0.tar.xz -O \
	mdadm-4.0.tar.xz

mkdir mdadm && tar xf mdadm-*.tar.* -C mdadm --strip-components 1
cd mdadm

#Fix for GCC 7.1
sed 's@-Werror@@' -i Makefile

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf mdadm

#reiserfsprogs
wget https://www.kernel.org/pub/linux/kernel/people/jeffm/reiserfsprogs/v3.6.27/reiserfsprogs-3.6.27.tar.xz -O \
	reiserfsprogs-3.6.27.tar.xz

mkdir reiserfsprogs && tar xf reiserfsprogs-*.tar.* -C reiserfsprogs --strip-components 1
cd reiserfsprogs

autoreconf -fiv 

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr\
    --libdir=/usr/lib64 --sbin=/sbin

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf reiserfsprogs

#valgrind
wget https://sourceware.org/ftp/valgrind/valgrind-3.13.0.tar.bz2 -O \
	valgrind-3.13.0.tar.bz2

mkdir valgrind && tar xf valgrind-*.tar.* -C valgrind --strip-components 1
cd valgrind

sed -i 's|/doc/valgrind||' docs/Makefile.in 

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr\
    --libdir=/usr/lib64 --datadir=/usr/share/doc/valgrind-3.13.0

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf valgrind

#xfsprogs
wget https://www.kernel.org/pub/linux/utils/fs/xfs/xfsprogs/xfsprogs-4.12.0.tar.xz -O \
	xfsprogs-4.12.0.tar.xz
	
mkdir xfsprogs && tar xf xfsprogs-*.tar.* -C xfsprogs --strip-components 1
cd xfsprogs

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} \
CC="gcc ${BUILD64}"     \
USE_ARCH=64             \
CXX="g++ ${BUILD64}"    \
make DEBUG=-DNDEBUG     \
     INSTALL_USER=root  \
     INSTALL_GROUP=root \
     PREFIX=/usr        \
     LIBDIR=/usr/lib64  \
     LOCAL_CONFIGURE_OPTIONS="--enable-readline"

sudo make PKG_DOC_DIR=/usr/share/doc/xfsprogs-4.12.0 install    
sudo make PKG_DOC_DIR=/usr/share/doc/xfsprogs-4.12.0 install-dev

sudo rm -rfv /usr/lib/libhandle.a                               
sudo rm -rfv /lib/libhandle.{a,la,so}                           
sudo ln -sfv ../../lib/libhandle.so.1 /usr/lib/libhandle.so     
sudo sed -i "s@libdir='/lib@libdir='/usr/lib@" /usr/lib/libhandle.la

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf xfsprogs

#LVM2
wget ftp://sources.redhat.com/pub/lvm2/releases/LVM2.2.02.171.tgz -O \
	LVM2.2.02.171.tgz

mkdir LVM2 && tar xf LVM2*.tgz -C LVM2 --strip-components 1
cd LVM2

SAVEPATH=$PATH PATH=$PATH:/sbin:/usr/sbin \
CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" \
USE_ARCH=64 PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr\
	--libdir=/usr/lib64 \
	--disable-static    \
    	--exec-prefix=      \
    	--enable-applib     \
    	--enable-cmdlib     \
    	--enable-pkgconfig  \
    	--enable-udev_sync
    
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} CC="gcc ${BUILD64}" USE_ARCH=64 \
CXX="g++ ${BUILD64}" make PREFIX=/usr LIBDIR=/usr/lib64

PATH=$SAVEPATH                 
unset SAVEPATH

export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

sudo make -C tools install_dmsetup_dynamic 
sudo make -C udev  install                 
sudo make -C libdm install

sudo mv /usr/lib/pkgconfig/devmapper.pc ${PKG_CONFIG_PATH64}/
sudo sudo mv /usr/lib/libdevmapper.so /usr/lib64/

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf LVM2

#sg3_utils
wget http://sg.danny.cz/sg/p/sg3_utils-1.42.tar.xz -O \
	sg3_utils-1.42.tar.xz

mkdir sg3_utils && tar xf sg3_utils-*.tar.* -C sg3_utils --strip-components 1
cd sg3_utils

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --disable-static

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf sg3_utils

#xfce4-power-manager
wget http://archive.xfce.org/src/xfce/xfce4-power-manager/1.6/xfce4-power-manager-1.6.0.tar.bz2 -O \
	xfce4-power-manager-1.6.0.tar.bz2

mkdir xfce4-power-manager && tar xf xfce4-power-manager-*.tar.* -C xfce4-power-manager --strip-components 1
cd xfce4-power-manager

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --sysconfdir=/etc

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf xfce4-power-manager

#lxde-icon-theme
wget https://downloads.sourceforge.net/lxde/lxde-icon-theme-0.5.1.tar.xz -O \
    lxde-icon-theme-0.5.1.tar.xz

mkdir lxde-icon-theme && tar xf lxde-icon-theme-*.tar.* -C lxde-icon-theme --strip-components 1
cd lxde-icon-theme

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 

sudo make PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" PREFIX=/usr LIBDIR=/usr/lib64 install
sudo gtk-update-icon-cache -qf /usr/share/icons/nuoveXT2

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf lxde-icon-theme

#libogg
wget http://downloads.xiph.org/releases/ogg/libogg-1.3.2.tar.xz -O \
    libogg-1.3.2.tar.xz

mkdir libogg && tar xf libogg-*.tar.* -C libogg --strip-components 1
cd libogg

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-static \
   --docdir=/usr/share/doc/libogg-1.3.2

make check
checkBuiltPackage

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libogg

#libvorbis
wget http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.5.tar.xz -O \
    libvorbis-1.3.5.tar.xz

mkdir libvorbis && tar xf libvorbis-*.tar.* -C libvorbis --strip-components 1
cd libvorbis

sed -i '/components.png \\/{n;d}' doc/Makefile.in

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-static 

make LIBS=-lm check
checkBuiltPackage

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install
sudo install -v -m644 doc/Vorbis* /usr/share/doc/libvorbis-1.3.5

ldconfig 

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libvorbis

wget ftp://ftp.alsa-project.org/pub/lib/alsa-lib-1.1.4.1.tar.bz2 -O \
    alsa-lib-1.1.4.1.tar.bz2

mkdir alsa-lib && tar xf alsa-lib-*.tar.* -C alsa-lib --strip-components 1
cd alsa-lib

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-static 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
make check
checkBuiltPackage

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

sudo install -v -d -m755 /usr/share/doc/alsa-lib-1.1.4.1/html/search &&
sudo install -v -m644 doc/doxygen/html/*.* \
                /usr/share/doc/alsa-lib-1.1.4.1/html 


sudo bash -c 'cat > /etc/asound.conf << "EOF"
pcm.!default {
  type hw
  card 0
}

ctl.!default {
  type hw           
  card 0
}
EOF'

sudo bash -c 'cat > /usr/share/alsa/alsa.conf << "EOF"
pcm.!default {
  type hw
  card 0
}

ctl.!default {
  type hw           
  card 0
}
EOF'

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf alsa-lib


#libcanberra
wget http://0pointer.de/lennart/projects/libcanberra/libcanberra-0.30.tar.xz -O \
    libcanberra-0.30.tar.xz

mkdir libcanberra && tar xf libcanberra-*.tar.* -C libcanberra --strip-components 1
cd libcanberra

intltoolize-prepare --force
autoconf
automake

cp ${CLFSSOURCES}/libcanberra-0.30-removedoc-nopulseaudio.patch ../

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 \
   --disable-static \
   --disable-oss \
   --disable-gtk-doc \
   --disable-gtk-doc-html \
   --disable-gtk-doc-pdf \
   --with-html-dir=no \
   --with-systemdsystemunitdir=no

patch -Np1 -i ../libcanberra-0.30-removedoc-nopulseaudio.patch

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf libcanberra

#xfce4-settings
wget http://archive.xfce.org/src/xfce/xfce4-settings/4.12/xfce4-settings-4.12.1.tar.bz2 -O \
	xfce4-settings-4.12.1.tar.bz2

mkdir xfce4-settings && tar xf xfce4-settings-*.tar.* -C xfce4-settings --strip-components 1
cd xfce4-settings

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --sysconfdir=/etc 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf xfce4-settings

#Xfdesktop
wget http://archive.xfce.org/src/xfce/xfdesktop/4.12/xfdesktop-4.12.4.tar.bz2 -O \
	xfdesktop-4.12.4.tar.bz2

mkdir xfdesktop && tar xf xfdesktop-*.tar.* -C xfdesktop --strip-components 1
cd xfdesktop

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf xfdesktop

#Xfwm4
wget http://archive.xfce.org/src/xfce/xfwm4/4.12/xfwm4-4.12.4.tar.bz2 -O \
	xfwm4-4.12.4.tar.bz2

mkdir xfwm4 && tar xf xfwm4-*.tar.* -C xfwm4 --strip-components 1
cd xfwm4

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf xfwm4

#desktop-file-utils
wget http://freedesktop.org/software/desktop-file-utils/releases/desktop-file-utils-0.23.tar.xz -O \
  desktop-file-utils-0.23.tar.xz

mkdir desktop-file-utils && tar xf desktop-file-utils-*.tar.* -C desktop-file-utils --strip-components 1
cd desktop-file-utils

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
    --prefix=/usr \
    --libdir=/usr/lib64

make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

sudo update-desktop-database /usr/share/applications

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf desktop-file-utils

#shared-mime-info
wget http://freedesktop.org/~hadess/shared-mime-info-1.8.tar.xz -O \
    shared-mime-info-1.8.tar.xz

mkdir sharedmimeinfo && tar xf shared-mime-info-*.tar.* -C sharedmimeinfo --strip-components 1
cd sharedmimeinfo

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 

make check
checkBuiltPackage

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf sharedmimeinfo

#polkit-gnome
wget http://ftp.gnome.org/pub/gnome/sources/polkit-gnome/0.105/polkit-gnome-0.105.tar.xz -O \
	polkit-gnome-0.105.tar.xz

mkdir polkit-gnome && tar xf polkit-gnome-*.tar.* -C polkit-gnome --strip-components 1
cd polkit-gnome

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure --prefix=/usr \
   --libdir=/usr/lib64 

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

sudo mkdir -p /etc/xdg/autostart &&
sudo bash -c 'cat > /etc/xdg/autostart/polkit-gnome-authentication-agent-1.desktop << "EOF"
[Desktop Entry]
Name=PolicyKit Authentication Agent
Comment=PolicyKit Authentication Agent
Exec=/usr/libexec/polkit-gnome-authentication-agent-1
Terminal=false
Type=Application
Categories=
NoDisplay=true
OnlyShowIn=GNOME;XFCE;Unity;
AutostartCondition=GNOME3 unless-session gnome
EOF'

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf polkit-gnome

#xfwm4
wget http://archive.xfce.org/src/xfce/xfwm4/4.12/xfwm4-4.12.4.tar.bz2 -O \
	xfwm4-4.12.4.tar.bz2

mkdir xfwm4 && tar xf xfwm4-*.tar.* -C xfwm4 --strip-components 1
cd xfwm4

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --sysconfdir=/etc \
     --disable-legacy-sm

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make install

sudo update-desktop-database 
sudo update-mime-database /usr/share/mime

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf xfwm4

#xfce4-session
wget http://archive.xfce.org/src/xfce/xfce4-session/4.12/xfce4-session-4.12.1.tar.bz2 -O \
	xfce4-session-4.12.1.tar.bz2

mkdir xfce4-session && tar xf xfce4-session-*.tar.* -C xfce4-session --strip-components 1
cd xfce4-session

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" ./configure \
     --prefix=/usr \
     --libdir=/usr/lib64 \
     --sysconfdir=/etc \
     --disable-legacy-sm

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make PREFIX=/usr LIBDIR=/usr/lib64
sudo make install

sudo update-desktop-database 
sudo update-mime-database /usr/share/mime

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf xfce4-session



#Generate .xinitrc here

cat > /home/overflyer/.xinitrc << "EOF"
#!/bin/sh
#
# ~/.xinitrc
#
# Executed by startx (run your window manager from here)

if [[ -f ~/.extend.xinitrc ]];then
	. ~/.extend.xinitrc
else
	DEFAULT_SESSION=xfce4-session
fi

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

# merge in defaults and keymaps

if [ -f $sysresources ]; then
    xrdb -merge $sysresources
fi

if [ -f $sysmodmap ]; then
    xmodmap $sysmodmap
fi

if [ -f "$userresources" ]; then
    xrdb -merge "$userresources"
fi

if [ -f "$usermodmap" ]; then
    xmodmap "$usermodmap"
fi

# start some nice programs

if [ -d /etc/X11/xinit/xinitrc.d ] ; then
    for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
        [ -x "$f" ] && . "$f"
    done
    unset f
fi

get_session(){
	local dbus_args=(--sh-syntax --exit-with-session)
	case $1 in
		awesome) dbus_args+=(awesome) ;;
		bspwm) dbus_args+=(bspwm-session) ;;
		budgie) dbus_args+=(budgie-desktop) ;;
		cinnamon) dbus_args+=(cinnamon-session) ;;
		deepin) dbus_args+=(startdde) ;;
		enlightenment) dbus_args+=(enlightenment_start) ;;
		fluxbox) dbus_args+=(startfluxbox) ;;
		gnome) dbus_args+=(gnome-session) ;;
		i3|i3wm) dbus_args+=(i3 --shmlog-size 0) ;;
		jwm) dbus_args+=(jwm) ;;
		kde) dbus_args+=(startkde) ;;
		lxde) dbus_args+=(startlxde) ;;
		lxqt) dbus_args+=(lxqt-session) ;;
		mate) dbus_args+=(mate-session) ;;
		xfce) dbus_args+=(xfce4-session) ;;
		openbox) dbus_args+=(openbox-session) ;;
		*) dbus_args+=($DEFAULT_SESSION) ;;
	esac

	echo "dbus-launch ${dbus_args[*]}"
}

exec $(get_session)


# twm &
# xclock -geometry 50x50-1+1 &
# xterm -geometry 80x50+494+51 &
# xterm -geometry 80x20+494-0 &
#exec xterm -geometry 80x66+0+0 -name login
EOF

## Xfce4 Applications ##

#gtksourceview3

#mousepad

#vte needs pcre2
#PCRE2
wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre2-10.23.tar.bz2 -O \
    pcre2-10.23.tar.bz2

mkdir pcre2 && tar xf pcre2-*.tar.* -C pcre2 --strip-components 1
cd pcre2

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
     --docdir=/usr/share/doc/pcre2-10.23 \
            --enable-unicode                    \
            --enable-pcre2-16                   \
            --enable-pcre2-32                   \
            --enable-pcre2grep-libz             \
            --enable-pcre2grep-libbz2           \
            --enable-pcre2test-libreadline      \
            --disable-static  \
            --libdir=/usr/lib64

PKG_CONFIG_PATH="${PKG_CONFIG_PATH64}" make LIBDIR=/usr/lib64 PREFIX=/usr
sudo make LIBDIR=/usr/lib64 PREFIX=/usr install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf pcre2

#vte
wget http://ftp.gnome.org/pub/gnome/sources/vte/0.48/vte-0.48.3.tar.xz -O \
    vte-0.48.3.tar.xz

mkdir vte && tar xf vte-*.tar.* -C vte --strip-components 1
cd vte

sudo cp ${CLFSSOURCES}/vte-0.48.3-removedoc.patch ../

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
    --disable-static \
    --libdir=/usr/lib64 \
    --sysconfdir=/etc \
    --enable-introspection \
    --disable-gtk-doc \
    --disable-gtk-doc-html \
    --disable-gtk-doc-pdf

patch -Np1 -i ../vte-0.48.3-removedoc.patch

checkBuiltPackage

make PREFIX=/usr LIBDIR=/usr/lib64

sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf vte

#xfce4-terminal
wget http://archive.xfce.org/src/apps/xfce4-terminal/0.8/xfce4-terminal-0.8.6.tar.bz2 -O \
	xfce4-terminal-0.8.6.tar.bz2

mkdir xfce4-terminal && tar xf xfce4-terminal-*.tar.* -C xfce4-terminal --strip-components 1
cd xfce4-terminal

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
    --libdir=/usr/lib64 

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf xfce4-terminal

#ristretto
wget http://archive.xfce.org/src/apps/ristretto/0.8/ristretto-0.8.2.tar.bz2 -O \
	ristretto-0.8.2.tar.bz2

mkdir ristretto && tar xf ristretto-*.tar.* -C ristretto --strip-components 1
cd ristretto

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
    --libdir=/usr/lib64 

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf ristretto

#xfce-notifyd
wget http://archive.xfce.org/src/apps/xfce4-notifyd/0.2/xfce4-notifyd-0.2.4.tar.bz2 -O \
	xfce4-notifyd-0.2.4.tar.bz2

mkdir xfce4-notifyd && tar xf xfce4-notifyd-*.tar.* -C xfce4-notifyd --strip-components 1
cd xfce4-notifyd

CC="gcc ${BUILD64}" CXX="g++ ${BUILD64}" USE_ARCH=64 \
PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} ./configure --prefix=/usr \
    --libdir=/usr/lib64 

PKG_CONFIG_PATH=${PKG_CONFIG_PATH64} make PREFIX=/usr LIBDIR=/usr/lib64
sudo make PREFIX=/usr LIBDIR=/usr/lib64 install

notify-send -i info Information "Hi ${USER}, This is a Test"

cd ${CLFSSOURCES}/xc/xfce4
checkBuiltPackage
sudo rm -rf xfce4-notifyd

sudo chown -Rv overflyer /home/overflyer
