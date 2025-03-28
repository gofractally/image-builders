ARG TOOL_CONFIG_IMAGE
ARG BASE_IMAGE

FROM ${TOOL_CONFIG_IMAGE} AS toolconfig
FROM ${BASE_IMAGE}

ARG TARGETARCH
ARG SOFTHSM_PIN="Ch4ng#Me!"

# Install deps
RUN export DEBIAN_FRONTEND=noninteractive   \
    && apt-get update                       \
    && apt-get install -yq                  \
        wget                                \
    && apt-get update                       \
    && apt-get install -yq                  \
        apt-transport-https                 \
        clang-format-18                     \
        curl                                \
        gdb                                 \
        gnupg2                              \
        iproute2                            \
        jq                                  \
        libnss3                             \
        softhsm2                            \
        unzip                               \
        xz-utils                            \
        xxd                                 \
    && apt-get clean -yq                    \
    && rm -rf /var/lib/apt/lists/*

# Use bash shell
ENV SHELL /bin/bash

# Need bash shell for ansi quotes
SHELL ["/bin/bash", "-c"]

# Configure SoftHSM with default pins
RUN softhsm2-util --init-token --slot 0 --label "psibase SoftHSM" --pin ${SOFTHSM_PIN} --so-pin ${SOFTHSM_PIN}

# Install psibase
ENV PSINODE_PATH=/root/psibase
ENV PATH=${PSINODE_PATH}/build/psidk/bin:$PATH
RUN mkdir -p ${PSINODE_PATH}    \
    && cd ${PSINODE_PATH}       \
    && git clone https://github.com/gofractally/psibase.git . \
    && git submodule update --init --recursive

# Add locally built rust programs to path
ENV PATH=${PSINODE_PATH}/build/rust/release:$PATH

# Copy in tool config
COPY --from=toolconfig / /

# Install nice-to-have rust/wasm tooling
RUN $CARGO_HOME/bin/cargo install \
    cargo-edit \
    wasm-tools \
    cargo-generate@0.22.0 

RUN npm i -g \
    eslint

# Expose ports
EXPOSE 8080

# Some nice-to-haves when using git inside the container
# (prettify terminal, git completion)
RUN echo $'\n\
parse_git_branch() {\n\
  git branch 2> /dev/null | sed -e "/^[^*]/d" -e "s/* \\(.*\\)/ (\\1)/"\n\
} \n\
export PS1="\u@\h \W\[\\033[32m\\]\\$(parse_git_branch)\\[\\033[00m\\] $ "\n\
#if [ -f ~/.git-completion.bash ]; then\n\
  #. ~/.git-completion.bash\n\
#fi\n\
# Source the git completion file to enable git-completion
. /usr/share/bash-completion/completions/git\n\
 \n\
alias ll="ls -alF"\n\
alias ls="ls --color=auto"\n\
export HOST_IP=$(ip route | awk "/default/ { print \$3 }") \
' >> /root/.bashrc

# Caches
ENV CCACHE_DIR=${PSINODE_PATH}/.caches/ccache
ENV SCCACHE_DIR=${PSINODE_PATH}/.caches/sccache
ENV CCACHE_CONFIGPATH=${PSINODE_PATH}/ccache.conf
ENV CARGO_COMPONENT_CACHE_DIR=${PSINODE_PATH}/.caches/cargo-component
ENV WASM_PACK_CACHE=${PSINODE_PATH}/.caches/wasm-pack

LABEL org.opencontainers.image.title="psibase-contributor"
LABEL org.opencontainers.image.description="Psibase development environment"
LABEL org.opencontainers.image.vendor="Fractally"
LABEL org.opencontainers.image.url="https://github.com/gofractally/image-builders/pkgs/container/psibase-contributor"
LABEL org.opencontainers.image.documentation="https://github.com/gofractally/image-builders"
LABEL org.opencontainers.image.source="https://github.com/gofractally/image-builders"