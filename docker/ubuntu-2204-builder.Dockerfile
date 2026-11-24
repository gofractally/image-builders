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
    python3-pip             \
    softhsm2                \
    strace                  \
    wget                    \
    zlib1g-dev              \
    zstd                    \
    #   Clang / LLVM
    && wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc \
    && add-apt-repository "deb http://apt.llvm.org/jammy/ llvm-toolchain-jammy-18 main" \
    && apt-get update           \
    && apt-get install -yq      \
    clang-18                \
    libclang-18-dev         \
    lld-18                  \
    llvm-18                 \
    && apt-get clean -yq        \
    && rm -rf /var/lib/apt/lists/*

RUN cd /root \
    && curl -LO https://archives.boost.io/release/1.88.0/source/boost_1_88_0.tar.bz2 \
    && tar xf boost_1_88_0.tar.bz2 \
    && cd boost_1_88_0 \
    && ./bootstrap.sh \
    && ./b2 --prefix=/usr/local --build-dir=build variant=release --with-chrono --with-date_time \
    --with-filesystem --with-iostreams --with-log --with-program_options --with-system --with-test install \
    && cd /root \
    && rm -rf boost*

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
        export NODEPATH=node-v24.22.1-linux-x64
    elif [ "arm64" = "$TARGETARCH" ]; then
        export NODEPATH=node-v24.22.1-linux-arm64
    fi

    cd /opt
    curl -LO https://nodejs.org/dist/v24.22.1/\$NODEPATH.tar.xz
    tar xf \$NODEPATH.tar.xz
    rm \$NODEPATH.tar.xz
    mv \$NODEPATH node-v24.22.1
    export PATH="/opt/node-v24.22.1/bin:$PATH"
EOT
ENV PATH=/opt/node-v24.22.1/bin:$PATH

ENV PATH=/opt/yarn:$PATH
RUN <<EOT bash
    set -eux
    mkdir -p /opt/yarn
    curl -L -o /opt/yarn/yarn.tar.gz https://github.com/yarnpkg/berry/archive/refs/tags/@yarnpkg/cli/4.18.0.tar.gz
    tar xzf /opt/yarn/yarn.tar.gz -C /opt/yarn/
    mv /opt/yarn/berry--yarnpkg-cli-4.18.0 /opt/yarn/berry-yarnpkg-cli-4-18-0
    rm /opt/yarn/yarn.tar.gz
    echo '#!/bin/sh' > /opt/yarn/yarn
    echo 'node /opt/yarn/berry-yarnpkg-cli-4-18-0/packages/yarnpkg-cli/bin/yarn.js "\$@"' >> /opt/yarn/yarn
    chmod 775 /opt/yarn/yarn
    export PATH="/opt/yarn:$PATH"
EOT

# Playwright browsers for e2e/. Version must match psibase e2e/@playwright/test.
ARG PLAYWRIGHT_VERSION=1.64.1
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/ms-playwright
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
RUN <<EOT bash
    set -eux
    mkdir -p /tmp/pw-install /opt/ms-playwright
    cd /tmp/pw-install
    npm init -y
    npm install --no-save "@playwright/test@${PLAYWRIGHT_VERSION}"
    npx playwright install --with-deps chromium webkit ffmpeg
    chmod -R a+rX /opt/ms-playwright
    cd /
    rm -rf /tmp/pw-install
EOT

RUN pip3 install 'websockets==10.4'

ENV RUSTUP_HOME=/opt/rustup
ENV CARGO_HOME=/opt/cargo
RUN cd /root \
    && curl --proto '=https' --tlsv1.2 -sSf -o rustup.sh https://sh.rustup.rs \
    && chmod 700 rustup.sh \
    && ./rustup.sh -y --no-modify-path --default-toolchain 1.98.0 \
    # Compile targets
    && /opt/cargo/bin/rustup target add \
    wasm32-unknown-unknown  \
    wasm32-wasip1           \
    # Cargo tools
    && /opt/cargo/bin/cargo install \
    cargo-component@0.15.0 --locked  \
    mdbook@0.4.52           \
    mdbook-linkcheck@0.7.7  \
    mdbook-mermaid@0.16.2   \
    mdbook-pagetoc@0.2.2    \
    mdbook-tabs@0.2.3       \
    sccache                 \
    wasm-pack@0.13.1        \
    cargo-generate@0.23.5   \
    # 
    && chmod -R 777 $RUSTUP_HOME \
    && chmod -R 777 $CARGO_HOME \
    && rm rustup.sh

ENV PATH=$CARGO_HOME/bin:$PATH
# Toolchain for branches that compile services with WebAssembly wide
# arithmetic and whose native code needs a C++23 standard library. Everything
# here is installed BESIDE the defaults above, which are unchanged, so a branch
# that does not ask for these tools builds exactly as before (psibase main was
# built and tested in this image without opting in). A build opts in with
#
#   PATH=/opt/binaryen-133/bin:/opt/wasi-sdk-29/bin:$PATH
#   WASI_SDK_PREFIX=/opt/wasi-sdk-29  RUSTUP_TOOLCHAIN=1.100.0
#   CC=clang-20  CXX=clang++-20
#
#   binaryen 133   wasm-opt that understands wide arithmetic (apt has 105)
#   wasi-sdk 29    clang 21 and a matching sysroot for wasm32-wasip1
#   Rust 1.100.0   first release whose 128-bit arithmetic is correct with the
#                  wide-arithmetic target feature; rustfmt is needed by the
#                  component bindings generator
#   clang 20       host compiler, with libstdc++ 13 for <format>
ARG BINARYEN_VERSION=133
ARG WASI_SDK_VERSION=29
ARG RUST_WIDE_ARITHMETIC_TOOLCHAIN=1.100.0
RUN <<EOT bash
    set -eux
    if [ "amd64" = "$TARGETARCH" ]; then
        export BINARYEN_ARCH=x86_64
        export WASI_ARCH=x86_64
    elif [ "arm64" = "$TARGETARCH" ]; then
        export BINARYEN_ARCH=aarch64
        export WASI_ARCH=arm64
    fi

    cd /opt
    curl -fLO https://github.com/WebAssembly/binaryen/releases/download/version_${BINARYEN_VERSION}/binaryen-version_${BINARYEN_VERSION}-\$BINARYEN_ARCH-linux.tar.gz
    tar xf binaryen-version_${BINARYEN_VERSION}-\$BINARYEN_ARCH-linux.tar.gz
    rm binaryen-version_${BINARYEN_VERSION}-\$BINARYEN_ARCH-linux.tar.gz
    mv binaryen-version_${BINARYEN_VERSION} binaryen-${BINARYEN_VERSION}

    curl -fLO https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-${WASI_SDK_VERSION}/wasi-sdk-${WASI_SDK_VERSION}.0-\$WASI_ARCH-linux.tar.gz
    tar xf wasi-sdk-${WASI_SDK_VERSION}.0-\$WASI_ARCH-linux.tar.gz
    rm wasi-sdk-${WASI_SDK_VERSION}.0-\$WASI_ARCH-linux.tar.gz
    mv wasi-sdk-${WASI_SDK_VERSION}.0-\$WASI_ARCH-linux wasi-sdk-${WASI_SDK_VERSION}

    /opt/cargo/bin/rustup toolchain install ${RUST_WIDE_ARITHMETIC_TOOLCHAIN} --profile default \
        --target wasm32-unknown-unknown --target wasm32-wasip1
    chmod -R 777 /opt/rustup /opt/cargo
EOT

RUN export DEBIAN_FRONTEND=noninteractive \
    && add-apt-repository -y ppa:ubuntu-toolchain-r/test \
    && add-apt-repository -y "deb http://apt.llvm.org/jammy/ llvm-toolchain-jammy-20 main" \
    && apt-get update \
    && apt-get install -yq g++-13 clang-20 lld-20 llvm-20-dev libclang-20-dev \
    && apt-get clean -yq \
    && rm -rf /var/lib/apt/lists/*
