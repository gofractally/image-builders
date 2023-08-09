FROM ubuntu:22.04

ARG TARGETARCH

RUN export DEBIAN_FRONTEND=noninteractive   \
    && apt-get update                       \
    && apt-get install -yq                  \
        wget                                \
    && wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key \
    && echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" | tee -a /etc/apt/sources.list.d/grafana.list \
    && apt-get update                       \
    && apt-get install -yq                  \
        apt-transport-https                 \
        curl                                \
        gnupg2                              \
        grafana                             \
        iproute2                            \
        prometheus                          \
        supervisor                          \
        unzip                               \
        xz-utils                            \
    && apt-get clean -yq                    \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

# Prometheus version 2.31
RUN useradd --no-create-home --shell /bin/false node_exporter \
    && useradd --no-create-home --shell /bin/false prome \
    && chown prome:prome /usr/bin/prometheus \
    && chown prome:prome /usr/bin/promtool \
    && chown -R prome:prome /etc/prometheus/consoles \
    && chown -R prome:prome /etc/prometheus/console_libraries

ENV SHELL /bin/bash

# Need bash shell for ansi quotes
SHELL ["/bin/bash", "-c"]

# Install extra tools used for admin-sys dashboards.
# Notes for arm: There is no arm64 package available for grok_exporter.
#                For websocat, we could use `websocat.aarch64-unknown-linux-musl`
#                ...We should switch from grok_exporter to mtail, which is in apt.
RUN <<EOT bash
    set -eux
    if [ "amd64" = "$TARGETARCH" ]; then
        export GROK_REPO=https://github.com/fstab/grok_exporter/releases/download/v1.0.0.RC5/
        export GROK_PACKAGE=grok_exporter-1.0.0.RC5.linux-amd64
        cd /root
        wget \$GROK_REPO\$GROK_PACKAGE.zip
        unzip grok_exporter-*.zip
        rm grok_exporter-*.zip
        ln -s /root/\$GROK_PACKAGE/grok_exporter /usr/local/bin/grok_exporter

        export WEBSOCAT_REPO=https://github.com/vi/websocat/releases/download/v1.11.0/
        export WEBSOCAT_PACKAGE=websocat.x86_64-unknown-linux-musl
        cd /root
        wget \$WEBSOCAT_REPO\$WEBSOCAT_PACKAGE
        mv \$WEBSOCAT_PACKAGE /usr/local/bin/websocat
        chmod a+x /usr/local/bin/websocat

    elif [ "arm64" = "$TARGETARCH" ]; then
        echo "Warning: Arm64 builds currently do not support admin-sys dashboards"
    fi
EOT

# Install Psidk
RUN wget https://github.com/gofractally/psibase/releases/download/rolling-release/psidk-ubuntu-2204.tar.gz \
    && tar xf psidk-ubuntu-2204.tar.gz          \
    && rm psidk-ubuntu-2204.tar.gz              \
    && cd /opt/psidk-ubuntu-2204/bin            \
    && rm psidk-cmake-args psitest


# Copy in tool config
COPY --from=ghcr.io/gofractally/http-tool-config / /

# Expose ports
# Psinode port
EXPOSE 8080
# Prometheus port
EXPOSE 9090
# Grafana port
EXPOSE 3000

# Set env variables
ENV PSIDK_HOME=/opt/psidk-ubuntu-2204
ENV PSINODE_PATH=/root/psibase
ENV PATH=$PSIDK_HOME/bin:$PATH
## Grafana vars
ENV GF_AUTH_ANONYMOUS_ORG_ROLE=Admin
ENV GF_AUTH_ANONYMOUS_ENABLED=true
ENV GF_AUTH_BASIC_ENABLED=false
ENV GF_SECURITY_ALLOW_EMBEDDING=true
ENV GF_SERVER_ROOT_URL=%(protocol)s://%(domain)s:%(http_port)s/grafana/
ENV GF_SERVER_SERVE_FROM_SUB_PATH=true

COPY docker/conf/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker/conf/psinode/psinode-entrypoint.sh /usr/local/bin/

LABEL org.opencontainers.image.title="psinode" \
    org.opencontainers.image.description="Containers using this image will run psinode with working admin-sys dashboards." \
    org.opencontainers.image.vendor="Psinq" \
    org.opencontainers.image.url="https://github.com/gofractally/image-builders/pkgs/container/psinode" \
    org.opencontainers.image.documentation="https://github.com/gofractally/image-builders"

WORKDIR $PSINODE_PATH
ENTRYPOINT ["psinode-entrypoint.sh"]
CMD ["psinode_db"]
