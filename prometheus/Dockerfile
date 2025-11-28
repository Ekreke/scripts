# Custom Prometheus Dockerfile
# This Dockerfile extends the official Prometheus image with additional configuration

FROM prom/prometheus:v2.54.1

# Labels for metadata
LABEL maintainer="Your Name <your.email@example.com>"
LABEL description="Custom Prometheus with additional exporters"
LABEL version="1.0"

# Set environment variables
ENV PROMETHEUS_CONFIG_DIR=/etc/prometheus
ENV PROMETHEUS_DATA_DIR=/prometheus
ENV PROMETHEUS_STORAGE_RETENTION=30d

# Copy custom configuration
COPY config/prometheus.yml $PROMETHEUS_CONFIG_DIR/prometheus.yml
COPY config/alertmanager.yml $PROMETHEUS_CONFIG_DIR/alertmanager.yml

# Copy rule files
COPY config/rules/ $PROMETHEUS_CONFIG_DIR/rules/

# Create non-root user (if needed)
# Note: Official Prometheus image already creates 'prometheus' user
# RUN addgroup -S prometheus && adduser -S -G prometheus prometheus

# Change ownership of configuration files
USER root
RUN chown -R prometheus:prometheus $PROMETHEUS_CONFIG_DIR

# Switch back to prometheus user
USER prometheus

# Expose ports
EXPOSE 9090

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:9090/-/healthy || exit 1

# Default command (inherits from base image)
CMD ["--config.file=/etc/prometheus/prometheus.yml", \
     "--storage.tsdb.path=/prometheus", \
     "--web.console.templates=/etc/prometheus/consoles", \
     "--web.console.libraries=/etc/prometheus/console_libraries", \
     "--web.listen-address=0.0.0.0:9090", \
     "--web.enable-admin-api", \
     "--storage.tsdb.retention.time=30d"]