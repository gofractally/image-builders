FROM ghcr.io/gofractally/psibase-builder-ubuntu-2204:daea6b22ce481912f5b4d3c9c4701eb87d99dc63

ARG TARGETARCH

# Install deps
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
        gdb                                 \
        gnupg2                              \
        grafana                             \
        iproute2                            \
        prometheus                          \
        unzip                               \
        xz-utils                            \
    && apt-get clean -yq                    \
    && rm -rf /var/lib/apt/lists/*

# Prometheus version 2.31
RUN useradd --no-create-home --shell /bin/false node_exporter \
    && useradd --no-create-home --shell /bin/false prome \
    && chown prome:prome /usr/bin/prometheus \
    && chown prome:prome /usr/bin/promtool \
    && chown -R prome:prome /etc/prometheus/consoles \
    && chown -R prome:prome /etc/prometheus/console_libraries

# Use bash shell
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

# Some nice-to-haves when using git inside the container
# (prettify terminal, git completion)
RUN echo $'\n\
parse_git_branch() {\n\
  git branch 2> /dev/null | sed -e "/^[^*]/d" -e "s/* \\(.*\\)/ (\\1)/"\n\
} \n\
export PS1="\u@\h \W\[\\033[32m\\]\\$(parse_git_branch)\\[\\033[00m\\] $ "\n\
if [ -f ~/.git-completion.bash ]; then\n\
  . ~/.git-completion.bash\n\
fi\n\
 \n\
alias ll="ls -alF"\n\
alias ls="ls --color=auto"\n\
export HOST_IP=$(ip route | awk "/default/ { print \$3 }") \
' >> /root/.bashrc

# Install psibase
ENV PSINODE_PATH=/root/psibase
ENV PATH=${PSINODE_PATH}/build/psidk/bin:$PATH
RUN mkdir -p ${PSINODE_PATH}    \
    && cd ${PSINODE_PATH}       \
    && git clone https://github.com/gofractally/psibase.git . \
    && git submodule update --init --recursive

# Expose ports
## Psinode
EXPOSE 8080
## Prometheus
EXPOSE 9090
## Grafana
EXPOSE 3000

# Copy in tool config
COPY --from=ghcr.io/gofractally/tool-config / /
RUN chmod -R 0700 /usr/local/bin/