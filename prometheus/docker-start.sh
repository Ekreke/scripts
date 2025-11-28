#!/bin/bash

# Docker-based Prometheus Start Script
# This script starts the complete Prometheus monitoring stack using Docker Compose

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_header() {
    echo -e "${BLUE}"
    echo "=================================="
    echo "  Prometheus Docker Stack"
    echo "=================================="
    echo -e "${NC}"
}

# Function to check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        print_info "Please install Docker first: https://docs.docker.com/get-docker/"
        exit 1
    fi
    print_success "Docker is installed"
}

# Function to check if Docker Compose is installed
check_docker_compose() {
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed"
        print_info "Please install Docker Compose: https://docs.docker.com/compose/install/"
        exit 1
    fi

    # Set docker-compose command
    if command -v docker-compose &> /dev/null; then
        DOCKER_COMPOSE="docker-compose"
    else
        DOCKER_COMPOSE="docker compose"
    fi
    print_success "Docker Compose is available: $DOCKER_COMPOSE"
}

# Function to check if Docker is running
check_docker_running() {
    if ! docker info &> /dev/null; then
        print_error "Docker is not running"
        print_info "Please start Docker first"
        exit 1
    fi
    print_success "Docker is running"
}

# Function to create necessary directories
create_directories() {
    print_info "Creating necessary directories..."
    mkdir -p config/rules
    mkdir -p grafana/provisioning/datasources
    mkdir -p grafana/provisioning/dashboards
    mkdir -p grafana/dashboards
    print_success "Directories created"
}

# Function to create Grafana datasource configuration
create_grafana_config() {
    print_info "Creating Grafana configuration..."

    cat > grafana/provisioning/datasources/prometheus.yml << 'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true

  - name: Node Exporter
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    editable: true

  - name: cAdvisor
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    editable: true
EOF

    cat > grafana/provisioning/dashboards/dashboard.yml << 'EOF'
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateInterval: 10s
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
EOF

    print_success "Grafana configuration created"
}

# Function to check if ports are available
check_ports() {
    print_info "Checking port availability..."

    local ports=(9090 9100 8080 3000 9093 9091)
    local services=("Prometheus" "Node Exporter" "cAdvisor" "Grafana" "AlertManager" "PushGateway")

    for i in "${!ports[@]}"; do
        local port=${ports[$i]}
        local service=${services[$i]}

        if lsof -i :$port &> /dev/null; then
            print_warning "Port $port ($service) is already in use"
            print_info "You may need to stop the service using this port or change the port mapping"
        else
            print_success "Port $port ($service) is available"
        fi
    done
}

# Function to start the stack
start_stack() {
    print_info "Starting Prometheus monitoring stack..."

    $DOCKER_COMPOSE up -d

    if [ $? -eq 0 ]; then
        print_success "Stack started successfully"
    else
        print_error "Failed to start stack"
        exit 1
    fi
}

# Function to wait for services to be ready
wait_for_services() {
    print_info "Waiting for services to be ready..."

    local services=("prometheus:9090" "grafana:3000")
    local max_wait=60
    local wait_time=0

    for service in "${services[@]}"; do
        local name=$(echo $service | cut -d: -f1)
        local port=$(echo $service | cut -d: -f2)

        print_info "Waiting for $name..."

        while [ $wait_time -lt $max_wait ]; do
            if curl -f http://localhost:$port &> /dev/null; then
                print_success "$name is ready"
                break
            fi

            sleep 5
            wait_time=$((wait_time + 5))

            if [ $wait_time -ge $max_wait ]; then
                print_warning "$name may still be starting up..."
            fi
        done

        wait_time=0
    done
}

# Function to check service status
check_status() {
    print_info "Checking service status..."
    $DOCKER_COMPOSE ps

    echo
    print_info "Service health checks:"

    # Check Prometheus
    if curl -f http://localhost:9090/-/healthy &> /dev/null; then
        print_success "Prometheus: Healthy"
    else
        print_warning "Prometheus: Still starting"
    fi

    # Check Grafana
    if curl -f http://localhost:3000/api/health &> /dev/null; then
        print_success "Grafana: Healthy"
    else
        print_warning "Grafana: Still starting"
    fi

    # Check Node Exporter
    if curl -f http://localhost:9100/metrics &> /dev/null; then
        print_success "Node Exporter: Running"
    else
        print_warning "Node Exporter: Still starting"
    fi
}

# Function to show access information
show_access_info() {
    echo
    print_header

    print_success "🎉 Prometheus monitoring stack is ready!"
    echo
    echo "Access URLs:"
    echo "  Prometheus Web UI: http://localhost:9090"
    echo "  Grafana Dashboard: http://localhost:3000"
    echo "    Username: admin"
    echo "    Password: admin123"
    echo "  cAdvisor: http://localhost:8080"
    echo "  AlertManager: http://localhost:9093"
    echo "  PushGateway: http://localhost:9091"
    echo
    echo "Useful Commands:"
    echo "  View logs:        $DOCKER_COMPOSE logs -f [service-name]"
    echo "  Check status:      $DOCKER_COMPOSE ps"
    echo "  Stop stack:        $DOCKER_COMPOSE down"
    echo "  Restart stack:     $DOCKER_COMPOSE restart"
    echo "  Update images:     $DOCKER_COMPOSE pull && $DOCKER_COMPOSE up -d"
    echo
    echo "Configuration Files:"
    echo "  Prometheus Config: ./config/prometheus.yml"
    echo "  Alert Rules:       ./config/rules/"
    echo "  Grafana Config:    ./grafana/provisioning/"
    echo
    print_info "First time setup for Grafana:"
    echo "  1. Import pre-built dashboards from the Grafana marketplace"
    echo "  2. Configure additional datasources if needed"
    echo "  3. Set up alert notifications"
}

# Function to stop the stack
stop_stack() {
    print_info "Stopping Prometheus monitoring stack..."
    $DOCKER_COMPOSE down
    print_success "Stack stopped"
}

# Function to remove all data
remove_all() {
    print_warning "This will remove all containers, networks, and data volumes"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        $DOCKER_COMPOSE down -v --remove-orphans
        docker system prune -f
        print_success "All containers and data removed"
    else
        print_info "Operation cancelled"
    fi
}

# Function to show logs
show_logs() {
    local service=$2
    if [ -z "$service" ]; then
        $DOCKER_COMPOSE logs -f
    else
        $DOCKER_COMPOSE logs -f $service
    fi
}

# Function to update images
update_images() {
    print_info "Pulling latest images..."
    $DOCKER_COMPOSE pull
    print_success "Images updated"

    print_info "Restarting stack with new images..."
    $DOCKER_COMPOSE up -d
    print_success "Stack restarted with new images"
}

# Function to show help
show_help() {
    echo "Prometheus Docker Stack Management Script"
    echo
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  start       Start the monitoring stack (default)"
    echo "  stop        Stop the monitoring stack"
    echo "  restart     Restart the monitoring stack"
    echo "  status      Show service status"
    echo "  logs        Show logs (optionally specify service name)"
    echo "  update      Update images and restart stack"
    echo "  clean       Remove all containers and data"
    echo "  help        Show this help message"
    echo
    echo "Examples:"
    echo "  $0                    # Start the stack"
    echo "  $0 logs prometheus    # Show Prometheus logs"
    echo "  $0 status             # Show service status"
}

# Main function
main() {
    print_header

    local command=${1:-start}

    case $command in
        "start")
            check_docker
            check_docker_compose
            check_docker_running
            create_directories
            create_grafana_config
            check_ports
            start_stack
            wait_for_services
            check_status
            show_access_info
            ;;
        "stop")
            stop_stack
            ;;
        "restart")
            check_docker
            check_docker_compose
            stop_stack
            sleep 2
            start_stack
            wait_for_services
            check_status
            ;;
        "status")
            check_docker
            check_docker_compose
            check_status
            ;;
        "logs")
            check_docker
            check_docker_compose
            show_logs "$@"
            ;;
        "update")
            check_docker
            check_docker_compose
            update_images
            ;;
        "clean")
            check_docker
            check_docker_compose
            remove_all
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"