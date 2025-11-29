#!/bin/bash

# PostgreSQL Docker Management Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Show usage
show_usage() {
    echo "Usage: $0 {up|down|build|logs|shell|reset|backup|restore|clean|status}"
    echo ""
    echo "Commands:"
    echo "  up      - Start PostgreSQL container"
    echo "  down    - Stop PostgreSQL container"
    echo "  build   - Build PostgreSQL image"
    echo "  logs    - Show container logs"
    echo "  shell   - Connect to PostgreSQL shell"
    echo "  reset   - Reset database (remove all data)"
    echo "  backup  - Backup database to file"
    echo "  restore - Restore database from backup file"
    echo "  clean   - Clean up containers and volumes"
    echo "  status  - Show container status"
    echo ""
    echo "Examples:"
    echo "  $0 up"
    echo "  $0 backup"
    echo "  $0 restore backup_20241129_120000.sql"
}

# Start PostgreSQL
start_postgres() {
    print_status "Starting PostgreSQL container..."
    docker-compose up -d
    print_status "PostgreSQL started successfully!"
    print_status "Connection string: postgresql://app_user:app_password@localhost:5432/app_db"
}

# Stop PostgreSQL
stop_postgres() {
    print_status "Stopping PostgreSQL container..."
    docker-compose down
    print_status "PostgreSQL stopped successfully!"
}

# Build PostgreSQL image
build_image() {
    print_status "Building PostgreSQL image..."
    docker build -t postgres-custom .
    print_status "Image built successfully!"
}

# Show logs
show_logs() {
    print_status "Showing PostgreSQL logs (Ctrl+C to exit)..."
    docker-compose logs -f postgres
}

# Connect to shell
connect_shell() {
    print_status "Connecting to PostgreSQL shell..."
    docker exec -it postgres_db psql -U app_user -d app_db
}

# Reset database
reset_database() {
    print_warning "This will delete all PostgreSQL data!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Resetting database..."
        docker-compose down -v
        docker-compose up -d
        print_status "Database reset successfully!"
    else
        print_status "Database reset cancelled."
    fi
}

# Backup database
backup_database() {
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="backup_${timestamp}.sql"
    print_status "Creating backup: $backup_file"
    docker exec postgres_db pg_dump -U app_user app_db > "$backup_file"
    print_status "Backup created successfully: $backup_file"
}

# Restore database
restore_database() {
    if [ -z "$1" ]; then
        print_error "Please specify a backup file."
        echo "Usage: $0 restore <backup_file.sql>"
        exit 1
    fi

    if [ ! -f "$1" ]; then
        print_error "Backup file not found: $1"
        exit 1
    fi

    print_warning "This will overwrite the current database with: $1"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Restoring database from $1..."
        docker exec -i postgres_db psql -U app_user -d app_db < "$1"
        print_status "Database restored successfully!"
    else
        print_status "Database restore cancelled."
    fi
}

# Clean up
clean_up() {
    print_warning "This will remove all containers and volumes!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Cleaning up containers and volumes..."
        docker-compose down -v --remove-orphans
        docker system prune -f
        print_status "Cleanup completed successfully!"
    else
        print_status "Cleanup cancelled."
    fi
}

# Show status
show_status() {
    print_status "PostgreSQL container status:"
    docker-compose ps
}

# Main script logic
case "$1" in
    up)
        start_postgres
        ;;
    down)
        stop_postgres
        ;;
    build)
        build_image
        ;;
    logs)
        show_logs
        ;;
    shell)
        connect_shell
        ;;
    reset)
        reset_database
        ;;
    backup)
        backup_database
        ;;
    restore)
        restore_database "$2"
        ;;
    clean)
        clean_up
        ;;
    status)
        show_status
        ;;
    *)
        show_usage
        exit 1
        ;;
esac