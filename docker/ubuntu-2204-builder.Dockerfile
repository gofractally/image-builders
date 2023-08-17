FROM ubuntu:22.04

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -yq software-properties-common \
    && apt-get update \
    && apt-get install -yq      \
        autoconf                \
        binaryen                \
        build-essential         \
        ccache                  \
        clang-15                \
        cmake                   \
        curl                    \
        git                     \
        libclang-15-dev         \
        libcurl4-openssl-dev    \
        libgbm-dev              \
        libgmp-dev              \
        libnss3-dev             \
        libssl-dev              \
        libtool                 \
        libusb-1.0-0-dev        \
        libzstd-dev             \
        lld-15                  \
        llvm-15                 \
        pkg-config              \
        python3-requests        \
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

ARG TARGETARCH

# https://github.com/WebAssembly/wasi-sdk/releases/tag/wasi-sdk-19
ENV WASI_SDK_PREFIX=/usr/lib/llvm-15
ENV PATH=${WASI_SDK_PREFIX}/bin:$PATH
RUN cd ${WASI_SDK_PREFIX}/lib/clang/15.0.7/                     \
    && curl -LO https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-19/libclang_rt.builtins-wasm32-wasi-19.0.tar.gz \
    && tar xf libclang_rt.builtins-wasm32-wasi-19.0.tar.gz      \
    && rm libclang_rt.builtins-wasm32-wasi-19.0.tar.gz          \
    && cd ${WASI_SDK_PREFIX}/share                              \
    && curl -LO https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-19/wasi-sysroot-19.0.tar.gz \
    && tar xf wasi-sysroot-19.0.tar.gz                          \
    && rm wasi-sysroot-19.0.tar.gz

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
ENV PATH=$CARGO_HOME/bin:$PATH
