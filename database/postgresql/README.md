# PostgreSQL Docker Setup

This directory contains a complete PostgreSQL setup using Docker and Docker Compose.

## Quick Start

### Using the Management Script (Recommended)

1. Start the PostgreSQL service:
   ```bash
   ./postgres.sh up
   ```

2. Check the status:
   ```bash
   ./postgres.sh status
   ```

3. View logs:
   ```bash
   ./postgres.sh logs
   ```

4. Connect to database shell:
   ```bash
   ./postgres.sh shell
   ```

5. Stop the service:
   ```bash
   ./postgres.sh down
   ```

### Using Docker Compose Directly

1. Start the PostgreSQL service:
   ```bash
   docker-compose up -d
   ```

2. Check the status:
   ```bash
   docker-compose ps
   ```

3. View logs:
   ```bash
   docker-compose logs postgres
   ```

4. Stop the service:
   ```bash
   docker-compose down
   ```

### Using Docker Build

1. Build the image:
   ```bash
   docker build -t postgres-custom .
   ```

2. Run the container:
   ```bash
   docker run -d \
     --name postgres_container \
     -p 5432:5432 \
     -e POSTGRES_DB=app_db \
     -e POSTGRES_USER=app_user \
     -e POSTGRES_PASSWORD=app_password \
     -v postgres_data:/var/lib/postgresql/data \
     postgres-custom
   ```

## Configuration

### Database Credentials
- **Database**: `app_db`
- **Username**: `app_user`
- **Password**: `app_password`
- **Port**: `5432`


## Connecting to the Database

### Using psql
```bash
psql -h localhost -p 5432 -U app_user -d app_db
```

### Using Docker
```bash
docker exec -it postgres_db psql -U app_user -d app_db
```

### Connection String
```
postgresql://app_user:app_password@localhost:5432/app_db
```

## Initialization Scripts

The `init/` directory contains SQL scripts that are executed when the database is first created:

- `01-create-database.sql` - Create additional databases
- `02-create-user.sql` - Create additional users
- `03-create-tables.sql` - Create tables and indexes
- `04-insert-sample-data.sql` - Insert sample data

## Persistence

Data is persisted using Docker volumes:
- `postgres_data` - PostgreSQL data directory

## Health Checks

The PostgreSQL container includes health checks that verify:
- Database is accepting connections
- Database is ready to accept queries

## Development Tips

### Using Management Script

1. **Reset Database**:
   ```bash
   ./postgres.sh reset
   ```

2. **Backup Database**:
   ```bash
   ./postgres.sh backup
   ```

3. **Restore Database**:
   ```bash
   ./postgres.sh restore backup_20241129_120000.sql
   ```

4. **View Logs in Real-time**:
   ```bash
   ./postgres.sh logs
   ```

5. **Connect to Database Shell**:
   ```bash
   ./postgres.sh shell
   ```

6. **Show Container Status**:
   ```bash
   ./postgres.sh status
   ```

7. **Clean Everything**:
   ```bash
   ./postgres.sh clean
   ```

### Using Docker Commands Directly

1. **Reset Database**:
   ```bash
   docker-compose down -v
   docker-compose up -d
   ```

2. **Backup Database**:
   ```bash
   docker exec postgres_db pg_dump -U app_user app_db > backup.sql
   ```

3. **Restore Database**:
   ```bash
   docker exec -i postgres_db psql -U app_user -d app_db < backup.sql
   ```

4. **View Logs in Real-time**:
   ```bash
   docker-compose logs -f postgres
   ```

5. **Connect to Database Shell**:
   ```bash
   docker exec -it postgres_db psql -U app_user -d app_db
   ```

## Customization

To customize the setup:

1. Modify environment variables in `docker-compose.yml`
2. Add/modify SQL scripts in `init/`
3. Update the `Dockerfile` for additional configurations
4. Adjust port mappings if needed

## Security Notes

- Change default passwords before production use
- Use environment variables or secrets for sensitive data
- Consider using Docker secrets for production deployments
- Enable SSL connections for production

## Troubleshooting

1. **Connection Issues**: Check if port 5432 is available
2. **Permission Issues**: Ensure proper volume permissions
3. **Initialization Failures**: Check logs for SQL syntax errors
4. **Memory Issues**: Adjust Docker memory limits if needed