patch_all
autoreconf -fi
./configure --enable-all-tools --disable-static --with-readline --host=x86_64-apple-darwin13 --prefix=/opt/osx
