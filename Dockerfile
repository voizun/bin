ARG PLATFORM=linux/amd64
ARG DISTRO=debian:trixie-backports

FROM --platform=$PLATFORM $DISTRO

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

RUN apt update
RUN apt install -y git pkg-config autoconf automake libtool make build-essential python3 libssl-dev libtatsu-dev upx-ucl

RUN mkdir /buildenv

# Build the dependencies

WORKDIR /buildenv

RUN git clone https://github.com/libimobiledevice/libplist.git; 
WORKDIR /buildenv/libplist
RUN ./autogen.sh --enable-static --disable-shared --without-cython; make -j`$nproc`; make install;

WORKDIR /buildenv

RUN git clone https://github.com/libimobiledevice/libimobiledevice-glue.git; 
WORKDIR /buildenv/libimobiledevice-glue
RUN ./autogen.sh --enable-static --disable-shared --without-cython; make -j`$nproc`; make install;

WORKDIR /buildenv

RUN git clone https://github.com/libimobiledevice/libusbmuxd.git; 
WORKDIR /buildenv/libusbmuxd
RUN ./autogen.sh --enable-static --disable-shared --without-cython; make -j`$nproc`; make install;

WORKDIR /buildenv

RUN git clone https://github.com/libimobiledevice/libimobiledevice.git; 
WORKDIR /buildenv/libimobiledevice
RUN ./autogen.sh --enable-static --disable-shared --without-cython; make -j`$nproc`; make install;

WORKDIR /buildenv

RUN apt remove -y libssl-dev

RUN git clone https://github.com/openssl/openssl.git --verbose --progress;
WORKDIR /buildenv/openssl
RUN ./Configure -static --static -mfpu=neon; make -j`$nproc`; make install;

WORKDIR /buildenv

# JitStreamer build time
RUN git clone https://github.com/jkcoxson/plist_plust.git;
RUN git clone https://github.com/jkcoxson/rusty_libimobiledevice.git;
RUN git clone https://github.com/jkcoxson/JitStreamer.git;

WORKDIR /buildenv/JitStreamer
RUN cargo build --release -C opt-level=s -C lto -C link-args=-Wl,-x,-S -C codegen-units=1 -C panic="abort" -C strip="symbols";

RUN upx --ultra-brute -o ./jit_streamer-(echo $PLATFORM | sed "s/\//-/g") target/release/jit_streamer

CMD ["/bin/sh", "mv", "/buildenv/JitStreamer/jit_streamer-*" "/github/workspace/"]
