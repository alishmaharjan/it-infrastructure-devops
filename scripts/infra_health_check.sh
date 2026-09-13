#!/bin/bash

LOG_FILE="/var/log/infra_health.log"
STATUS_FILE="/opt/it-infrastructure-devops/health/health_status.txt"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
WARNING=0

# CPU usage
CPU=$(top -bn1 | awk '/Cpu\(s\)/ {print 100 - $8}')

# RAM usage
RAM=$(free | awk '/Mem:/ {printf "%.0f", ($3/$2)*100}')

# Root disk usage
DISK=$(df / | awk 'NR==2 {gsub("%",""); print $5}')

# Docker service
if systemctl is-active --quiet docker; then
    DOCKER="RUNNING"
else
    DOCKER="STOPPED"
    WARNING=1
fi

# Backend container
if docker inspect -f '{{.State.Running}}' test-backend 2>/dev/null | grep -q true; then
    BACKEND="RUNNING"
else
    BACKEND="STOPPED"
    WARNING=1
fi

# Disk warning
if [ "$DISK" -gt 85 ]; then
    WARNING=1
    echo "[$TIMESTAMP] [WARNING] Root disk usage is ${DISK}%" >> "$LOG_FILE"
fi

# Overall status
if [ "$WARNING" -eq 0 ]; then
    OVERALL="OK"
else
    OVERALL="WARNING"
fi

# Terminal output
echo "Infrastructure Health Check"
echo "Time: $TIMESTAMP"
echo "CPU Usage: ${CPU}%"
echo "RAM Usage: ${RAM}%"
echo "Root Disk Usage: ${DISK}%"
echo "Docker Service: $DOCKER"
echo "Backend Container: $BACKEND"
echo "----------------------------------------"
echo "[$OVERALL] Infrastructure health check passed."

# Write data for Flask dashboard
cat > "$STATUS_FILE" <<EOF
TIMESTAMP=$TIMESTAMP
CPU=$CPU
RAM=$RAM
DISK=$DISK
DOCKER=$DOCKER
BACKEND=$BACKEND
OVERALL=$OVERALL
EOF
