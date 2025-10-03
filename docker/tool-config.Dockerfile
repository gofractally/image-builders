# This image is a scratch image that copies third-party config files into the image.

FROM scratch

# psinode config
COPY docker/conf/psinode/scripts /usr/local/bin/
COPY docker/conf/psinode/configs /root/example-psinode-configs/
COPY docker/conf/direnv/config.toml /root/.config/direnv/config.toml