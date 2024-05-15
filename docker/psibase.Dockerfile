# Workaround because the ARG doesn't expand properly in COPY
# https://stackoverflow.com/a/63472135
ARG psinode_version
FROM ghcr.io/gofractally/psinode:$psinode_version as psinode

FROM ubuntu:22.04
COPY --from=psinode /opt/psidk-ubuntu-2204/bin/psibase /opt/psidk-ubuntu-2204/bin/psibase
COPY --from=psinode /opt/psidk-ubuntu-2204/share /opt/psidk-ubuntu-2204/share

ENV PSIDK_HOME=/opt/psidk-ubuntu-2204
ENV PATH=$PSIDK_HOME/bin:$PATH

LABEL org.opencontainers.image.title="psibase"
LABEL org.opencontainers.image.description="This docker image provides access to the Psibase CLI tool for local or remote administration of a Psinode instance."
LABEL org.opencontainers.image.vendor="Fractally"
LABEL org.opencontainers.image.url="https://github.com/gofractally/psibase-docker-image/pkgs/container/psibase"
LABEL org.opencontainers.image.documentation="https://github.com/gofractally/image-builders"
LABEL org.opencontainers.image.source="https://github.com/gofractally/image-builders"

ENTRYPOINT ["psibase"]
