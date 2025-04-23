#!/bin/bash

# Exit on error
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to print status messages
print_status() {
    echo -e "${GREEN}[*] $1${NC}"
}

# Function to print warning messages
print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

# Function to print error messages
print_error() {
    echo -e "${RED}[!] $1${NC}"
}

# Default values
APP_URL=${APP_URL:-"http://localhost:8080"}
HEALTH_ENDPOINT="/health"
API_ENDPOINT="/api/v1/status"
MAX_RETRIES=5
RETRY_INTERVAL=10

# Function to check if a service is healthy
check_health() {
    local url="$APP_URL$HEALTH_ENDPOINT"
    local retries=0
    
    while [ $retries -lt $MAX_RETRIES ]; do
        if curl -s -f "$url" | grep -q "healthy"; then
            print_status "Service is healthy"
            return 0
        fi
        
        print_warning "Service not healthy yet, retrying in $RETRY_INTERVAL seconds..."
        sleep $RETRY_INTERVAL
        retries=$((retries + 1))
    done
    
    print_error "Service health check failed after $MAX_RETRIES attempts"
    return 1
}

# Function to verify API functionality
verify_api() {
    local url="$APP_URL$API_ENDPOINT"
    
    print_status "Verifying API functionality..."
    if ! curl -s -f "$url" > /dev/null; then
        print_error "API verification failed"
        return 1
    fi
    
    print_status "API is functioning correctly"
    return 0
}

# Function to check database connectivity
check_database() {
    print_status "Checking database connectivity..."
    
    if ! pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME"; then
        print_error "Database connection failed"
        return 1
    fi
    
    print_status "Database connection successful"
    return 0
}

# Function to verify application logs
check_logs() {
    print_status "Checking application logs for errors..."
    
    if docker logs "$(docker ps -q --filter name=app)" 2>&1 | grep -i "error\|exception\|fail"; then
        print_warning "Found errors in application logs"
        return 1
    fi
    
    print_status "No critical errors found in logs"
    return 0
}

# Main verification process
main() {
    print_status "Starting deployment verification..."
    
    # Check service health
    if ! check_health; then
        exit 1
    fi
    
    # Verify API functionality
    if ! verify_api; then
        exit 1
    fi
    
    # Check database connectivity
    if ! check_database; then
        exit 1
    fi
    
    # Check application logs
    if ! check_logs; then
        print_warning "Deployment completed with warnings"
        exit 0
    fi
    
    print_status "Deployment verification completed successfully"
    exit 0
}

# Run main function
main 