# Use the official Grafana image as base
FROM grafana/grafana:latest

# Set environment variables
ENV GF_SECURITY_ADMIN_USER=admin
ENV GF_SECURITY_ADMIN_PASSWORD=admin123
ENV GF_INSTALL_PLUGINS=

# Create volumes for persistent data
VOLUME ["/var/lib/grafana", "/etc/grafana/provisioning", "/var/log/grafana"]

# Expose port
EXPOSE 3000

# Default command
CMD ["grafana-server"]