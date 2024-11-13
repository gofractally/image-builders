FROM ubuntu:22.04

ARG TARGETARCH

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -yq software-properties-common \
    && apt-get update \
    && apt-get install -yq      \
    autoconf                \
    binaryen                \
    build-essential         \
    ccache                  \
    cmake                   \
    curl                    \
    git                     \
    libssl-dev              \
    libtool                 \
    pkg-config              \
    python3-requests        \
    strace                  \
    wget                    \
    zstd                    \
    #   Clang / LLVM
    && wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc \
    && add-apt-repository "deb http://apt.llvm.org/jammy/ llvm-toolchain-jammy-16 main" \
    && apt-get update           \
    && apt-get install -yq      \
    clang-16                \
    libclang-16-dev         \
    lld-16                  \
    llvm-16                 \
    && apt-get clean -yq        \
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

RUN <<EOT bash
    set -eux
    if [ "amd64" = "$TARGETARCH" ]; then
        export NODEPATH=node-v20.11.0-linux-x64
    elif [ "arm64" = "$TARGETARCH" ]; then
        export NODEPATH=node-v20.11.0-linux-arm64
    fi

    cd /opt
    curl -LO https://nodejs.org/dist/v20.11.0/\$NODEPATH.tar.xz
    tar xf \$NODEPATH.tar.xz
    rm \$NODEPATH.tar.xz
    mv \$NODEPATH node-v20.11.0
    export PATH="/opt/node-v20.11.0/bin:$PATH"
    npm i -g yarn
EOT
ENV PATH=/opt/node-v20.11.0/bin:$PATH

ENV RUSTUP_HOME=/opt/rustup
ENV CARGO_HOME=/opt/cargo
RUN cd /root \
    && curl --proto '=https' --tlsv1.2 -sSf -o rustup.sh https://sh.rustup.rs \
    && chmod 700 rustup.sh \
    && ./rustup.sh -y --no-modify-path \
    # Compile targets
    && /opt/cargo/bin/rustup target add \
    wasm32-unknown-unknown  \
    wasm32-wasi             \
    wasm32-wasip1           \
    # Cargo tools
    && /opt/cargo/bin/cargo install \
    cargo-component@0.13.2  \
    mdbook                  \
    mdbook-linkcheck        \
    mdbook-mermaid          \
    mdbook-pagetoc          \
    sccache                 \
    wasm-pack               \
    # 
    && chmod -R 777 $RUSTUP_HOME \
    && chmod -R 777 $CARGO_HOME \
    && rm rustup.sh
ENV PATH=$CARGO_HOME/bin:$PATH
