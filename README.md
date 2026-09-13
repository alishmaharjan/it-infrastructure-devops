# IT Infrastructure & DevOps Trainee Practical Implementation

 1. Project Overview

This project implements a small production-style IT infrastructure environment on Ubuntu Server using Docker, Docker Compose, Nginx, PostgreSQL, Bash automation, cron, Prometheus, and Node Exporter.

The implementation covers:

* Linux server administration and SSH hardening
* Firewall configuration using UFW
* Docker and Docker Compose deployment
* Nginx reverse proxy
* Flask backend application
* PostgreSQL database with persistent storage
* Automated infrastructure health checks
* Automated database backups
* Database restore verification
* Prometheus and Node Exporter monitoring
* Git feature-branch workflow and documentation

---

## 2. Architecture

```text
                         Client / Browser
                                
                                | HTTP :80
                                v
                       
                             Nginx       
                        Reverse Proxy    
                       
                                |
                                | HTTP :5000
                                v
                    
                        Flask Backend    
                        test-backend     
                       
                                |
                                | PostgreSQL :5432
                                v
                       
                          PostgreSQL     
                           test-db       
                                |
                                v
                       Persistent Volume
                       postgres_data


          Monitoring
              |
              ----------------------
              |                    |
              v                    v
            
        Node Exporter| --->  Prometheus  
           :9100               :9090    
          
```

All application and monitoring containers communicate through the Docker bridge network:


it-infrastructure-devops_devops-net
```

 3. Technology Stack

| Component        | Technology              |
| ---------------- | ----------------------- |
| Operating System | Ubuntu Server 24.04 LTS |
| Containerization | Docker                  |
| Orchestration    | Docker Compose          |
| Reverse Proxy    | Nginx                   |
| Backend          | Python Flask            |
| Database         | PostgreSQL 16           |
| Monitoring       | Prometheus              |
| Metrics Exporter | Node Exporter           |
| Automation       | Bash + cron             |
| Firewall         | UFW                     |
| Version Control  | Git                     |
| Repository       | GitHub                  |

 4. Project Structure

```text
it-infrastructure-devops/
├── backend/
│   ├── app.py
│   ├── requirements.txt
│   └── Dockerfile
├── monitoring/
│   └── prometheus.yml
├── nginx/
│   └── nginx.conf
├── scripts/
│   ├── db_backup.sh
│   └── infra_health_check.sh
├── docker-compose.yml
├── .gitignore
└── README.md
```

The `.env` file contains database credentials and is intentionally excluded from Git using `.gitignore`.

---

## 5. Server Configuration

Server

* Hostname: `devops-server`
* Operating System: Ubuntu Server 24.04 LTS
* SSH port: `2222`
* Application HTTP port: `80`

### SSH Security

SSH was configured to:

* Use port `2222`
* Allow SSH key authentication
* Disable password authentication
* Disable root SSH login

Example connection:

```bash
ssh -p 2222 alish@SERVER_IP
```

SSH configuration can be validated with:

```bash
sudo sshd -t
```

---

## 6. Firewall

UFW is configured to allow only the required services:

```text
2222/tcp - SSH
80/tcp   - HTTP
443/tcp  - HTTPS
```

Check firewall status:

```bash
sudo ufw status verbose
```

The Docker monitoring ports `9090` and `9100` are not exposed to the host network and therefore do not need to be opened in UFW.

---

## 7. Environment Variables

Database credentials are stored in `.env` instead of directly inside `docker-compose.yml`.

Example:

```env
POSTGRES_DB=devopsdb
POSTGRES_USER=devops
POSTGRES_PASSWORD=devops****
```

The `.env` file is excluded from Git:

```gitignore
.env
```

Verify:

```bash
git check-ignore -v .env
```

---

## 8. Docker Compose Deployment

Start the complete infrastructure:

```bash
docker compose up -d
```

Check service status:

```bash
docker compose ps
```

Stop the infrastructure:

```bash
docker compose down
```

Rebuild the backend:

```bash
docker compose up -d --build
```

Validate the Compose configuration:

```bash
docker compose config
```

### Services

| Service       | Container     | Internal Port |   Host Port |
| ------------- | ------------- | ------------: | ----------: |
| Nginx         | test-nginx    |            80 |          80 |
| Flask Backend | test-backend  |          5000 | Not exposed |
| PostgreSQL    | test-db       |          5432 | Not exposed |
| Prometheus    | prometheus    |          9090 | Not exposed |
| Node Exporter | node-exporter |          9100 | Not exposed |

---

## 9. Nginx Reverse Proxy

Nginx is the public entry point for the application.

Traffic flow:

```text
Client
  |
  | HTTP :80
  v
Nginx
  |
  | backend:5000
  v
Flask
```

The Flask backend is not directly exposed to the host. Nginx forwards requests through the Docker network.

Test from the server:

```bash
curl http://localhost/
```

Or from another machine:

```bash
curl http://SERVER_IP/
```

---

## 10. Backend Health Check

The Flask application provides:

```text
GET /health
```

Expected response:

```json
{"status":"healthy"}
```

The backend can be tested from inside the container:

```bash
docker exec test-backend \
python -c "import urllib.request; print(urllib.request.urlopen('http://127.0.0.1:5000/health').read().decode())"
```

---

## 11. PostgreSQL Database

PostgreSQL uses a persistent Docker volume:

```text
it-infrastructure-devops_postgres_data
```

Check volumes:

```bash
docker volume ls
```

Check database health:

```bash
docker compose ps
```

The PostgreSQL container uses a health check based on:

```bash
pg_isready
```

---

## 12. Infrastructure Health Check

Script:

```text
scripts/infra_health_check.sh
```

The script checks:

* CPU usage
* RAM usage
* Root filesystem usage
* Docker service status
* Flask backend container status

A warning is generated when root disk usage exceeds 85% or an important service/container is stopped.

Run manually:

```bash
sudo /opt/scripts/infra_health_check.sh
```

Health logs are stored in:

```text
/var/log/infra_health.log
```

### Cron Schedule

The health check runs every 15 minutes.

Cron configuration:

```text
/etc/cron.d/infra-health-check
```

Schedule:

```cron
*/15 * * * * root /opt/scripts/infra_health_check.sh
```

Verify cron:

```bash
systemctl status cron
```

---

## 13. Database Backup

Backup script:

```text
scripts/db_backup.sh
```

Backups are stored in:

```text
/var/backups/db/
```

The script uses PostgreSQL `pg_dump` and gzip compression.

Run manually:

```bash
sudo /opt/scripts/db_backup.sh
```

Example backup:

```text
/var/backups/db/db_backup_YYYYMMDD_HHMMSS.sql.gz
```

List backups:

```bash
sudo ls -lh /var/backups/db/
```

### Automated Backup

The backup runs daily at 02:00.

Cron configuration:

```text
/etc/cron.d/db-backup
```

Schedule:

```cron
0 2 * * * root /opt/scripts/db_backup.sh >> /var/log/db_backup.log 2>&1
```

Backup log:

```text
/var/log/db_backup.log
```

---

## 14. Database Restore Procedure

Create a temporary restore database:

```bash
docker exec -it test-db \
psql -U devops -d postgres \
-c "CREATE DATABASE restore_test;"
```

Restore a compressed backup:

```bash
gunzip -c /var/backups/db/db_backup_YYYYMMDD_HHMMSS.sql.gz | \
docker exec -i test-db psql -U devops -d restore_test
```

Verify restored tables:

```bash
docker exec test-db \
psql -U devops -d restore_test -c "\dt"
```

Verify test data:

```bash
docker exec test-db \
psql -U devops -d restore_test \
-c "SELECT * FROM backup_test;"
```

After verification, remove the temporary database:

```bash
docker exec test-db \
psql -U devops -d postgres \
-c "DROP DATABASE restore_test;"
```

---

## 15. Monitoring

The monitoring stack consists of:

* Prometheus
* Node Exporter

Prometheus configuration:

```text
monitoring/prometheus.yml
```

Prometheus scrapes Node Exporter every 15 seconds.

Configuration:

```yaml
global:
  scrape_interval: 15s
```

Node Exporter exposes system metrics internally on:

```text
node-exporter:9100
```

Prometheus runs internally on:

```text
prometheus:9090
```

Neither monitoring service is exposed directly to the host.

### Verify Node Exporter

```bash
docker exec prometheus \
wget -qO- http://node-exporter:9100/metrics | head
```

### Verify Prometheus Target

```bash
docker exec prometheus \
wget -qO- http://localhost:9090/api/v1/targets
```

The Node Exporter target should report:

```text
health: up
```

---

## 16. Docker Network

All application and monitoring services use:

```text
devops-net
```

Inspect the network:

```bash
docker network inspect it-infrastructure-devops_devops-net
```

This provides internal service-to-service communication without unnecessarily exposing container ports to the host.

---

## 17. Verification Checklist

### Linux / Security

```bash
hostnamectl
```

```bash
sudo ss -tulpn
```

```bash
sudo ufw status verbose
```

```bash
sudo sshd -t
```

### Docker

```bash
docker --version
```

```bash
docker compose version
```

```bash
docker compose ps
```

### Application

```bash
curl http://localhost/
```

```bash
docker exec test-backend \
python -c "import urllib.request; print(urllib.request.urlopen('http://127.0.0.1:5000/health').read().decode())"
```

### Health Check

```bash
sudo /opt/scripts/infra_health_check.sh
```

### Backup

```bash
sudo /opt/scripts/db_backup.sh
```

```bash
sudo ls -lh /var/backups/db/
```

### Monitoring

```bash
docker exec prometheus \
wget -qO- http://node-exporter:9100/metrics | head
```

```bash
docker compose logs prometheus
```

---

## 18. Git Workflow

Development was organized using feature branches.

Branches used:

```text
main
feature/docker-setup
feature/monitoring
feature/scripts
feature/config-security
feature/docs
```

Meaningful commits include:

```text
Add Docker Compose web stack
Add Prometheus monitoring
Add infrastructure health and backup scripts
Move database credentials to environment variables
```

View the history:

```bash
git log --oneline --decorate --all --graph
```

Check working tree:

```bash
git status
```

---

## 19. Deployment Summary

The infrastructure can be started with:

```bash
git clone <repo-url>
cd it-infrastructure-devops
```

Create the environment file:

```bash
nano .env
```

Add:

```env
POSTGRES_DB=devopsdb
POSTGRES_USER=devops
POSTGRES_PASSWORD=secure-password
```

Then deploy:

```bash
docker compose up -d
```

Verify:

```bash
docker compose ps
```

Test:

```bash
curl http://localhost/
```

---

## 20. Troubleshooting

### Check all containers

```bash
docker compose ps
```

### Check application logs

```bash
docker compose logs backend
```

### Check Nginx logs

```bash
docker compose logs nginx
```

### Check PostgreSQL logs

```bash
docker compose logs db
```

### Check Prometheus logs

```bash
docker compose logs prometheus
```

### Restart infrastructure

```bash
docker compose restart
```

### Rebuild containers
docker compose up -d --build

## 21. Evidence / Screenshots

The following screenshots should be included with the practical assignment:

1. Ubuntu server and hostname

   <img width="440" height="279" alt="image" src="https://github.com/user-attachments/assets/e7522644-8544-41fc-a9aa-5d2fec9f438c" />
   



2. SSH connection using port `2222`

<img width="897" height="93" alt="image" src="https://github.com/user-attachments/assets/c9cf89c2-02a9-4e48-80d6-06ce9678efce" />



   
3. UFW status showing allowed ports

<img width="549" height="197" alt="image" src="https://github.com/user-attachments/assets/f8904ca2-450e-4fd1-b915-3fd85e98d7ee" />


   
4. `docker compose ps` showing running services

<img width="896" height="225" alt="image" src="https://github.com/user-attachments/assets/0f1546aa-0883-4c6b-b4d3-17d2ab0055fa" />

   
5. Application accessed through Nginx

<img width="777" height="613" alt="image" src="https://github.com/user-attachments/assets/1e8364f0-ba22-4611-9ec2-717d3149aaf0" />

   
6. Backend `/health` response

<img width="666" height="161" alt="image" src="https://github.com/user-attachments/assets/e8b82a29-b27b-41f0-aee2-d0959b86700d" />


 
7. Docker network inspection

<img width="594" height="162" alt="image" src="https://github.com/user-attachments/assets/7a1dae69-68d5-4166-a67e-cb8cef9adc8a" />



8. Cron configuration / execution evidence

<img width="761" height="70" alt="image" src="https://github.com/user-attachments/assets/03e707a3-9432-4538-b910-21948025debc" />


    
9. Successful database backup

<img width="625" height="95" alt="image" src="https://github.com/user-attachments/assets/98637130-8fb2-42b0-ae3d-a673db2e5cd5" />


10. Git log showing feature branches and meaningful commits

<img width="699" height="487" alt="image" src="https://github.com/user-attachments/assets/2129886b-c4b5-4d10-9f19-4b3f9595c84a" />


---

## 22. Project Status

| Requirement                 | Status      

| Ubuntu Server               | Complete    
| Dedicated user              | Complete    
| SSH key authentication      | Complete    
| SSH port 2222               | Complete    
| Root SSH disabled           | Complete    
| Docker Compose              | Complete    
| Nginx reverse proxy         | Complete    
| Flask backend               | Complete    
| PostgreSQL                  | Complete    
| Persistent volume           | Complete    
| Infrastructure health check | Complete    
| Health-check cron           | Complete    
| Database backup             | Complete    
| Backup cron                 | Complete    
| Restore testing             | Complete    
| Prometheus                  | Complete    
| Node Exporter               | Complete    
| Git feature branches        | Complete    
| GitHub repository           | Complete    
| README documentation        | complete     
| Verification screenshots    | complete     

---

## 23. Author
Alish Maharjan

Repository:`it-infrastructure-devops`
