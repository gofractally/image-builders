ARG TOOL_CONFIG_IMAGE
FROM ${TOOL_CONFIG_IMAGE} AS toolconfig

FROM ubuntu:22.04

ARG TARGETARCH
ARG RELEASE_TAG
ARG SOFTHSM_PIN="Ch4ng#Me!"

RUN export DEBIAN_FRONTEND=noninteractive   \
    && apt-get update                       \
    && apt-get install -yq                  \
    wget                                    \
    apt-transport-https                     \
    curl                                    \
    gnupg2                                  \
    iproute2                                \
    softhsm2                                \
    unzip                                   \
    xz-utils                                \
    && apt-get clean -yq                    \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

ENV SHELL /bin/bash

# Need bash shell for ansi quotes
SHELL ["/bin/bash", "-c"]

# Install Psidk
RUN wget https://github.com/gofractally/psibase/releases/download/${RELEASE_TAG}/psidk-ubuntu-2204.tar.gz \
    && tar xf psidk-ubuntu-2204.tar.gz          \
    psidk-ubuntu-2204/bin/psinode           \
    psidk-ubuntu-2204/bin/psibase           \
    psidk-ubuntu-2204/share/psibase/        \
    psidk-ubuntu-2204/share/man/            \
    && rm psidk-ubuntu-2204.tar.gz              \
    && cp psidk-ubuntu-2204/share/man/* /usr/share/man/man1/


# Configure SoftHSM with default pins
RUN softhsm2-util --init-token --slot 0 --label "psibase SoftHSM" --pin ${SOFTHSM_PIN} --so-pin ${SOFTHSM_PIN}

# Copy in tool config
COPY --from=toolconfig / /

# Set env variables
ENV PSIDK_HOME=/opt/psidk-ubuntu-2204
ENV PSINODE_PATH=/root/psibase
ENV PATH=$PSIDK_HOME/bin:$PATH

LABEL org.opencontainers.image.title="psinode"
LABEL org.opencontainers.image.description="Containers using this image will run psinode"
LABEL org.opencontainers.image.vendor="Fractally"
LABEL org.opencontainers.image.url="https://github.com/gofractally/image-builders/pkgs/container/psinode"
LABEL org.opencontainers.image.documentation="https://github.com/gofractally/image-builders"
LABEL org.opencontainers.image.source="https://github.com/gofractally/image-builders"

WORKDIR $PSINODE_PATH
CMD ip route | awk '/default/ { print $3 }' > /tmp/host_ip && export HOST_IP=$(cat /tmp/host_ip) && psinode psinode_db
