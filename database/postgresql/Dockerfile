FROM postgres:16-alpine

# Set environment variables
ENV POSTGRES_DB=app_db
ENV POSTGRES_USER=app_user
ENV POSTGRES_PASSWORD=app_password
ENV POSTGRES_INITDB_ARGS=--encoding=UTF-8 --lc-collate=C --lc-ctype=C

# Create the data directory
RUN mkdir -p /var/lib/postgresql/data && \
    chown -R postgres:postgres /var/lib/postgresql/data

# Set the data directory
ENV PGDATA=/var/lib/postgresql/data/pgdata

# Copy initialization scripts
COPY init/ /docker-entrypoint-initdb.d/

# Expose PostgreSQL port
EXPOSE 5432

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD pg_isready -U app_user -d app_db

# Use the default postgres entrypoint
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["postgres"]