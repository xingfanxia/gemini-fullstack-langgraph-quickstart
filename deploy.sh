#!/bin/bash
# Deploy script for LangGraph + Dify services
# This script manages two separate Docker Compose stacks with a single Caddy reverse proxy

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIFY_DIR="${SCRIPT_DIR}/../dify/docker"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Function to build LangGraph image
build_langgraph() {
    print_status "Building LangGraph Docker image..."
    if docker build -t gemini-fullstack-langgraph . > /dev/null 2>&1; then
        print_success "LangGraph image built successfully"
    else
        print_error "Failed to build LangGraph image"
        exit 1
    fi
}

# Function to start LangGraph services
start_langgraph() {
    print_status "Starting LangGraph services..."
    
    # Build the image first
    build_langgraph
    
    # Start the services
    if docker compose up -d; then
        print_success "LangGraph services started successfully"
    else
        print_error "Failed to start LangGraph services"
        exit 1
    fi
}

# Function to start Dify services
start_dify() {
    print_status "Starting Dify services..."
    
    cd /home/xingfanxia/dify/docker
    if docker compose up -d; then
        print_success "Dify services started successfully"
        cd /home/xingfanxia/gemini-fullstack-langgraph-quickstart
    else
        print_error "Failed to start Dify services"
        cd /home/xingfanxia/gemini-fullstack-langgraph-quickstart
        exit 1
    fi
}

# Function to stop LangGraph services
stop_langgraph() {
    print_status "Stopping LangGraph services..."
    if docker compose down; then
        print_success "LangGraph services stopped successfully"
    else
        print_warning "Some LangGraph services may still be running"
    fi
}

# Function to stop Dify services
stop_dify() {
    print_status "Stopping Dify services..."
    
    cd /home/xingfanxia/dify/docker
    if docker compose down; then
        print_success "Dify services stopped successfully"
        cd /home/xingfanxia/gemini-fullstack-langgraph-quickstart
    else
        print_warning "Some Dify services may still be running"
        cd /home/xingfanxia/gemini-fullstack-langgraph-quickstart
    fi
}

# Function to show status
show_status() {
    print_status "=== LangGraph Services ==="
    docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
    
    echo ""
    print_status "=== Dify Services ==="
    cd /home/xingfanxia/dify/docker
    docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
    cd /home/xingfanxia/gemini-fullstack-langgraph-quickstart
    
    echo ""
    print_status "If all services are running:"
    print_status "  • Main Site: https://demos.computelabs.ai"
    print_status "  • LangGraph: https://gs.demos.computelabs.ai"
    print_status "  • Dify Web: https://dify.demos.computelabs.ai"
    print_status "  • Dify API: https://api.dify.demos.computelabs.ai"
    print_status "  • Open WebUI: https://oui.demos.computelabs.ai"
}

# Function to show logs
show_logs() {
    local service=$2
    case $service in
        "langgraph")
            print_status "Showing LangGraph logs..."
            docker compose logs -f
            ;;
        "dify")
            print_status "Showing Dify logs..."
            cd /home/xingfanxia/dify/docker
            docker compose logs -f
            cd /home/xingfanxia/gemini-fullstack-langgraph-quickstart
            ;;
        "caddy")
            print_status "Showing Caddy logs..."
            docker compose logs -f caddy
            ;;
        "open-webui")
            print_status "Showing Open WebUI logs..."
            docker compose logs -f open-webui
            ;;
        *)
            print_status "Showing all LangGraph logs..."
            docker compose logs -f
            ;;
    esac
}

# Main script logic
case $1 in
    "start")
        check_docker
        case $2 in
            "langgraph")
                start_langgraph
                ;;
            "dify")
                start_dify
                ;;
            *)
                print_status "Starting all services..."
                start_langgraph
                start_dify
                print_success "All services started successfully!"
                print_status "Services available at:"
                print_status "  • Main Site: https://demos.computelabs.ai"
                print_status "  • LangGraph: https://gs.demos.computelabs.ai"
                print_status "  • Dify Web: https://dify.demos.computelabs.ai"
                print_status "  • Dify API: https://api.dify.demos.computelabs.ai"
                print_status "  • Open WebUI: https://oui.demos.computelabs.ai"
                ;;
        esac
        ;;
    "stop")
        case $2 in
            "langgraph")
                stop_langgraph
                ;;
            "dify")
                stop_dify
                ;;
            *)
                print_status "Stopping all services..."
                stop_langgraph
                stop_dify
                print_success "All services stopped successfully!"
                ;;
        esac
        ;;
    "restart")
        check_docker
        case $2 in
            "langgraph")
                stop_langgraph
                start_langgraph
                ;;
            "dify")
                stop_dify
                start_dify
                ;;
            "caddy")
                print_status "Restarting Caddy..."
                docker compose restart caddy
                print_success "Caddy restarted successfully"
                ;;
            "open-webui")
                print_status "Restarting Open WebUI..."
                docker compose restart open-webui
                print_success "Open WebUI restarted successfully"
                ;;
            *)
                print_status "Restarting all services..."
                stop_langgraph
                stop_dify
                start_langgraph
                start_dify
                print_success "All services restarted successfully!"
                ;;
        esac
        ;;
    "status")
        show_status
        ;;
    "logs")
        show_logs $@
        ;;
    "build")
        check_docker
        build_langgraph
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|build} [service]"
        echo ""
        echo "Commands:"
        echo "  start [service]    - Start all services or specific service (langgraph|dify)"
        echo "  stop [service]     - Stop all services or specific service (langgraph|dify)"
        echo "  restart [service]  - Restart all services or specific service (langgraph|dify|caddy|open-webui)"
        echo "  status            - Show status of all services"
        echo "  logs [service]    - Show logs for all or specific service (langgraph|dify|caddy|open-webui)"
        echo "  build             - Build LangGraph Docker image"
        echo ""
        echo "Examples:"
        echo "  $0 start                    # Start all services"
        echo "  $0 start langgraph         # Start only LangGraph services"
        echo "  $0 restart caddy           # Restart only Caddy"
        echo "  $0 logs open-webui         # Show Open WebUI logs"
        echo "  $0 status                  # Show status of all services"
        exit 1
        ;;
esac 