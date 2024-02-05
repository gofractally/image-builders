FROM ubuntu:20.04

ARG TARGETARCH

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
        libssl-dev              \
        libstdc++-11-dev        \
        libtool                 \
        libzstd-dev             \
        pkg-config              \
        python3-requests        \
        strace                  \
        wget                    \
        zstd                    \
#   Clang / LLVM
    && wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc \
    && add-apt-repository "deb http://apt.llvm.org/focal/ llvm-toolchain-focal-16 main" \
    && apt-get update           \
    && apt-get install -yq      \
        clang-16                \
        libclang-16-dev         \
        lld-16                  \
        llvm-16                 \
    && apt-get clean -yq        \
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

# https://github.com/WebAssembly/wasi-sdk/releases/tag/wasi-sdk-20
ENV WASI_SDK_PREFIX=/usr/lib/llvm-16
ENV PATH=${WASI_SDK_PREFIX}/bin:$PATH
RUN cd ${WASI_SDK_PREFIX}/lib/clang/16/                         \
    && curl -LO https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-20/libclang_rt.builtins-wasm32-wasi-20.0.tar.gz \
    && tar xf libclang_rt.builtins-wasm32-wasi-20.0.tar.gz      \
    && rm libclang_rt.builtins-wasm32-wasi-20.0.tar.gz          \
    && cd ${WASI_SDK_PREFIX}/share                              \
    && curl -LO https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-20/wasi-sysroot-20.0.tar.gz \
    && tar xf wasi-sysroot-20.0.tar.gz                          \
    && rm wasi-sysroot-20.0.tar.gz

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
    && /opt/cargo/bin/cargo install \
        cargo-component     \
        mdbook              \
        mdbook-linkcheck    \
        mdbook-mermaid      \
        mdbook-pagetoc      \
        sccache             \
        wasm-pack           \
    && chmod -R 777 $RUSTUP_HOME \
    && chmod -R 777 $CARGO_HOME \
    && rm rustup.sh
ENV PATH=${CARGO_HOME}/bin:$PATH
