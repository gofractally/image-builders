FROM ubuntu:24.04

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
    clang-18                \
    libclang-18-dev         \
    lld-18                  \
    llvm-18                 \
    libboost1.83-dev        \
    libboost-chrono1.83-dev          \
    libboost-date-time1.83-dev       \
    libboost-filesystem1.83-dev      \
    libboost-iostreams1.83-dev       \
    libboost-log1.83-dev             \
    libboost-program-options1.83-dev \
    libboost-system1.83-dev          \
    libboost-test1.83-dev            \
    && apt-get clean -yq        \
    && rm -rf /var/lib/apt/lists/*

# https://github.com/WebAssembly/wasi-sdk/releases/tag/wasi-sdk-24
ENV WASI_SDK_PREFIX=/usr/lib/llvm-18
ENV PATH=${WASI_SDK_PREFIX}/bin:$PATH
RUN cd ${WASI_SDK_PREFIX}/lib/clang/18/                         \
    && curl -LO https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-24/libclang_rt.builtins-wasm32-wasi-24.0.tar.gz \
    && mkdir -p lib/wasi lib/wasip1 lib/wasip2                  \
    && tar xf libclang_rt.builtins-wasm32-wasi-24.0.tar.gz -C lib/wasi --strip-components=1 \
    && rm libclang_rt.builtins-wasm32-wasi-24.0.tar.gz          \
    && ln lib/wasi/libclang_rt.builtins-wasm32.a lib/wasip1     \
    && ln lib/wasi/libclang_rt.builtins-wasm32.a lib/wasip2     \
    && cd ${WASI_SDK_PREFIX}/share                              \
    && curl -LO https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-24/wasi-sysroot-24.0.tar.gz \
    && tar xf wasi-sysroot-24.0.tar.gz --transform 's/^[^\/]*/wasi-sysroot/' \
    && rm wasi-sysroot-24.0.tar.gz

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
EOT
ENV PATH=/opt/node-v20.11.0/bin:$PATH

ENV PATH=/opt/yarn:$PATH
RUN <<EOT bash
    mkdir -p /opt/yarn
    curl -L -o /opt/yarn/yarn.tar.gz https://github.com/yarnpkg/berry/archive/refs/tags/@yarnpkg/cli/4.9.1.tar.gz
    tar xzf /opt/yarn/yarn.tar.gz -C /opt/yarn/
    mv /opt/yarn/berry--yarnpkg-cli-4.9.1 /opt/yarn/berry-yarnpkg-cli-4-9-1
    rm /opt/yarn/yarn.tar.gz
    echo "n1"
    echo "#!/bin/sh" > /opt/yarn/yarn
    echo "n2"
    echo 'node /opt/yarn/berry-yarnpkg-cli-4-9-1/packages/yarnpkg-cli/bin/yarn.js "$@"' >> /opt/yarn/yarn
    echo "n3"
    chmod 775 /opt/yarn/yarn
    echo "n4"
    cat /opt/yarn/yarn
    echo "n5"
    export PATH="/opt/yarn:$PATH"
    echo "PATH=$PATH"
    echo "n6"
    /opt/yarn/yarn --version
EOT

ENV RUSTUP_HOME=/opt/rustup
ENV CARGO_HOME=/opt/cargo
RUN cd /root \
    && curl --proto '=https' --tlsv1.2 -sSf -o rustup.sh https://sh.rustup.rs \
    && chmod 700 rustup.sh \
    && ./rustup.sh -y --no-modify-path \
    # Compile targets
    && /opt/cargo/bin/rustup target add \
    wasm32-unknown-unknown  \
    wasm32-wasip1           \
    # Cargo tools
    && /opt/cargo/bin/cargo install \
    cargo-component@0.20.0 --locked  \
    mdbook                  \
    mdbook-linkcheck        \
    mdbook-mermaid          \
    mdbook-pagetoc          \
    mdbook-tabs             \
    sccache                 \
    wasm-pack               \
    cargo-generate@0.22.0 \
    # 
    && chmod -R 777 $RUSTUP_HOME \
    && chmod -R 777 $CARGO_HOME \
    && rm rustup.sh

ENV PATH=$CARGO_HOME/bin:$PATH