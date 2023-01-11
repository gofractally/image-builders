FROM ubuntu:jammy

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -yq software-properties-common \
    && add-apt-repository -y ppa:ubuntu-toolchain-r/test \
    && apt-get update \
    && apt-get install -yq      \
        autoconf                \
        binaryen                \
        build-essential         \
        ccache                  \
        clang                   \
        clang++                 \
        cmake                   \
        curl                    \
        g++                     \
        gcc                     \
        git                     \
        libcurl4-openssl-dev    \
        libgbm-dev              \
        libgmp-dev              \
        libnss3-dev             \
        libssl-dev              \
        libstdc++-11-dev        \
        libtool                 \
        libusb-1.0-0-dev        \
        libzstd-dev             \
        pkg-config              \
        zstd                    \
    && apt-get clean -yq \
    && rm -rf /var/lib/apt/lists/*

RUN cd /root \
    && curl -LO https://boostorg.jfrog.io/artifactory/main/release/1.81.0/source/boost_1_81_0.tar.bz2 \
    && tar xf boost_1_81_0.tar.bz2 \
    && cd boost_1_81_0 \
    && ./bootstrap.sh \
    && ./b2 --prefix=/usr/local --build-dir=build variant=release --with-chrono --with-date_time \
            --with-filesystem --with-iostreams --with-log --with-program_options --with-system --with-test install \
    && cd /root \
    && rm -rf boost*

RUN cd /opt \
    && curl -LO https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-17/wasi-sdk-17.0-linux.tar.gz \
    && tar xf wasi-sdk-17.0-linux.tar.gz \
    && curl -LO https://nodejs.org/dist/v16.17.0/node-v16.17.0-linux-x64.tar.xz \
    && tar xf node-v16.17.0-linux-x64.tar.xz \
    && rm *.tar.* \
    && export PATH="/opt/node-v16.17.0-linux-x64/bin:$PATH" \
    && npm i -g yarn

ENV RUSTUP_HOME=/opt/rustup
ENV CARGO_HOME=/opt/cargo

RUN cd /root \
    && curl --proto '=https' --tlsv1.2 -sSf -o rustup.sh https://sh.rustup.rs \
    && chmod 700 rustup.sh \
    && ./rustup.sh -y --no-modify-path \
    && /opt/cargo/bin/rustup target add wasm32-wasi \
    && /opt/cargo/bin/cargo install mdbook mdbook-linkcheck mdbook-mermaid sccache  \
    && chmod -R 777 $RUSTUP_HOME \
    && chmod -R 777 $CARGO_HOME \
    && rm rustup.sh

ENV WASI_SDK_PREFIX=/opt/wasi-sdk-17.0
ENV PATH=/opt/cargo/bin:/opt/node-v16.17.0-linux-x64/bin:$PATH
