# This image is a scratch image that downloads third-party applications that are not available
#   in the system package manager.

FROM scratch

# prometheus config
COPY docker/conf/prometheus/prometheus.yml /etc/prometheus/prometheus.yml

# psinode config
COPY docker/conf/psinode/scripts /usr/local/bin/
COPY docker/conf/psinode/configs/http.config /root/psibase/psinode_db/http.config
COPY docker/conf/psinode/configs/https.config /root/psibase/psinode_db/config

# grok_exporter config
COPY docker/conf/grok_exporter/patterns /etc/grok_exporter/
COPY docker/conf/grok_exporter/grok-exporter.yml /root/grok-exporter.yml

# grafana
COPY --chown=grafana:grafana --chmod=644 docker/conf/grafana/psinode-datasources.yaml /usr/share/grafana/conf/provisioning/datasources/psinode-datasources.yaml
COPY --chown=grafana:grafana --chmod=644 docker/conf/grafana/psinode-dashboard.yaml /usr/share/grafana/conf/provisioning/dashboards/psinode-dashboard.yaml
COPY docker/conf/grafana/dashboards /var/lib/grafana/dashboards
COPY docker/conf/grafana/grafana-psinode.ini /etc/grafana/grafana-psinode.ini
