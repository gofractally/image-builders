FROM ubuntu:20.04

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -yq software-properties-common \
    && add-apt-repository -y ppa:ubuntu-toolchain-r/test \
    && apt-get update \
    && apt-get install -yq      \
        autoconf                \
        build-essential         \
        cmake                   \
        curl                    \
        g++-11                  \
        gcc-11                  \
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
        python3-requests        \
        zstd                    \
    && apt-get clean -yq \
    && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 100 \
    && update-alternatives --install /usr/bin/cc cc /usr/bin/gcc-11 100 \
    && update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++-11 100

# Ccache
RUN cd /root \
    && curl -LO https://github.com/ccache/ccache/releases/download/v4.3/ccache-4.3.tar.gz \
    && tar xf ccache-4.3.tar.gz \
    && cd /root/ccache-4.3 \
    && cmake . \
    && make -j \
    && make -j install \
    && cd /root \
    && rm -rf ccache*

# Boost
RUN cd /root \
    && curl -LO https://boostorg.jfrog.io/artifactory/main/release/1.78.0/source/boost_1_78_0.tar.gz \
    && tar xf boost_1_78_0.tar.gz \
    && cd boost_1_78_0 \
    && ./bootstrap.sh \
    && ./b2 --prefix=/usr/local --build-dir=build variant=release --with-chrono --with-date_time \
            --with-filesystem --with-iostreams --with-log --with-program_options --with-system --with-test install \
    && cd /root \
    && rm -rf boost*

# Clang+llvm
# https://github.com/llvm/llvm-project/releases/tag/llvmorg-15.0.6
# (Clang V15.0.7 is the version of clang found in wasi sdk 19)
ARG TARGETARCH
RUN <<EOT bash
    set -eux
    if [ "amd64" = "$TARGETARCH" ]; then
        export CLANGPATH=clang+llvm-15.0.6-x86_64-linux-gnu-ubuntu-18.04
    elif [ "arm64" = "$TARGETARCH" ]; then
        export CLANGPATH=clang+llvm-15.0.6-aarch64-linux-gnu
    fi

    cd /opt
    curl -LO https://github.com/llvm/llvm-project/releases/download/llvmorg-15.0.6/\$CLANGPATH.tar.xz
    tar xf \$CLANGPATH.tar.xz
    rm \$CLANGPATH.tar.xz
    mv \$CLANGPATH clang+llvm-15.0.6
EOT
ENV LD_LIBRARY_PATH=/opt/clang+llvm-15.0.6/lib/

# Wasi-sdk
# https://github.com/WebAssembly/wasi-sdk/releases/tag/wasi-sdk-19
ENV WASI_SDK_PREFIX=/opt/clang+llvm-15.0.6
ENV PATH=${WASI_SDK_PREFIX}/bin:$PATH
RUN cd ${WASI_SDK_PREFIX}/lib/clang/15.0.6/ \
    && curl -LO https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-19/libclang_rt.builtins-wasm32-wasi-19.0.tar.gz \
    && tar xf libclang_rt.builtins-wasm32-wasi-19.0.tar.gz      \
    && rm libclang_rt.builtins-wasm32-wasi-19.0.tar.gz          \
    && cd ${WASI_SDK_PREFIX}/share                              \
    && curl -LO https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-19/wasi-sysroot-19.0.tar.gz \
    && tar xf wasi-sysroot-19.0.tar.gz                          \
    && rm wasi-sysroot-19.0.tar.gz

# Node
RUN <<EOT bash
    set -eux
    if [ "amd64" = "$TARGETARCH" ]; then
        export NODEPATH=node-v16.17.0-linux-x64
    elif [ "arm64" = "$TARGETARCH" ]; then
        export NODEPATH=node-v16.17.0-linux-arm64
    fi

    cd /opt
    curl -LO https://nodejs.org/dist/v16.17.0/\$NODEPATH.tar.xz
    tar xf \$NODEPATH.tar.xz
    rm \$NODEPATH.tar.xz
    mv \$NODEPATH node-v16.17.0
    export PATH="/opt/node-v16.17.0/bin:$PATH"
    npm i -g yarn
EOT
ENV PATH=/opt/node-v16.17.0/bin:$PATH

# Binaryen
RUN <<EOT bash
    set -eux
    if [ "amd64" = "$TARGETARCH" ]; then
        export BINARYEN_PATH=binaryen-version_113-x86_64-linux
        export BINARYEN_SHA=a70f8643b17029da05f437c8939e4c388a09aa6bcd53156c58038161828bfab4
    elif [ "arm64" = "$TARGETARCH" ]; then
        export BINARYEN_PATH=binaryen-version_113-arm64-macos
        export BINARYEN_SHA=f9dd94c653252a8f2f403956ebf786a9688ca4fa7d2b435d2ab45d624e5d12fc
    fi

    cd /opt
    curl -LO https://github.com/WebAssembly/binaryen/releases/download/version_113/\$BINARYEN_PATH.tar.gz
    echo \$BINARYEN_SHA \$BINARYEN_PATH.tar.gz > \$BINARYEN_PATH.tar.gz.sha256
    sha256sum -c \$BINARYEN_PATH.tar.gz.sha256
    tar xf \$BINARYEN_PATH.tar.gz
    rm \$BINARYEN_PATH.tar.gz
EOT
ENV PATH=/opt/binaryen-version_113/bin:$PATH

# Rust
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
ENV PATH=${CARGO_HOME}/bin:$PATH
