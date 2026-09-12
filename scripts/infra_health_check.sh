#!/bin/bash

LOG_FILE="/var/log/infra_health.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
WARNING=0

echo "Infrastructure Health Check"
echo "Time: $TIMESTAMP"

# CPU usage
CPU=$(top -bn1 | awk '/Cpu\(s\)/ {print 100 - $8}')
echo "CPU Usage: ${CPU}%"

# RAM usage
RAM=$(free | awk '/Mem:/ {printf "%.0f", ($3/$2)*100}')
echo "RAM Usage: ${RAM}%"

# Root disk usage
DISK=$(df / | awk 'NR==2 {gsub("%",""); print $5}')
echo "Root Disk Usage: ${DISK}%"

# Check root disk
if [ "$DISK" -gt 85 ]; then
    echo "[WARNING] Root disk usage is ${DISK}%"
    echo "[$TIMESTAMP] [WARNING] Root disk usage is ${DISK}%" >> "$LOG_FILE"
    WARNING=1
fi

# Check Docker service
if systemctl is-active --quiet docker; then
    echo "Docker Service: RUNNING"
else
    echo "[WARNING] Docker service is not running"
    echo "[$TIMESTAMP] [WARNING] Docker service is not running" >> "$LOG_FILE"
    WARNING=1
fi

# Check backend container
if docker inspect -f '{{.State.Running}}' test-backend 2>/dev/null | grep -q true; then
    echo "Backend Container: RUNNING"
else
    echo "[WARNING] Backend container test-backend is stopped"
    echo "[$TIMESTAMP] [WARNING] Backend container test-backend is stopped" >> "$LOG_FILE"
    WARNING=1
fi

echo "----------------------------------------"

if [ "$WARNING" -eq 0 ]; then
    echo "[OK] Infrastructure health check passed."
else
    echo "[WARNING] One or more infrastructure checks failed."
fi

echo "=============..................."
