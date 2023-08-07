FROM ubuntu:22.04

COPY --from=psinode-test /opt/psidk-ubuntu-2204/bin/psibase /opt/psidk-ubuntu-2204/bin/psibase

ENV PSIDK_HOME=/opt/psidk-ubuntu-2204
ENV PATH=$PSIDK_HOME/bin:$PATH

LABEL org.opencontainers.image.title="psibase" \
    org.opencontainers.image.description="This docker image provides access to the Psibase CLI tool for local or remote administration of a Psinode instance." \
    org.opencontainers.image.vendor="Psinq" \
    org.opencontainers.image.url="https://github.com/gofractally/psibase-docker-image/pkgs/container/psibase" \
    org.opencontainers.image.documentation="https://github.com/gofractally/image-builders"

ENTRYPOINT ["psibase"]
