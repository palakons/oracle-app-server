# Oracle App Server Infrastructure Configuration

Deployment configurations, systemd services, and Nginx reverse proxy settings for hosting multiple applications on an Ubuntu Oracle Compute instance.

## 📌 Architecture Overview

This server hosts three independent GitHub repositories behind a single system-level Nginx reverse proxy with HTTPS (Let's Encrypt):

| Domain | Application | Local Port | Authentication | Public Ingress |
|---|---|---|---|---|
| `trade.longwarp.com` | `palakons/alpha-trader-v2` | `3000` (Web), `8000` (API) | Basic Auth over HTTPS | Ports 80, 443 |
| `toll.longwarp.com` | `palakons/thai_unified_toll_map` | `3001` | None (Public) | Ports 80, 443 |
| `shabu.longwarp.com` | `palakons/shabu_nub_nub` | `3002` | None (Public) | Ports 80, 443 |

---

## 📁 Repository Structure

```
oracle-app-server/
├── nginx/
│   ├── trade.longwarp.com.conf   # Nginx proxy config + Basic Auth for Alpha Trader
│   ├── toll.longwarp.com.conf    # Nginx proxy config for Toll Map
│   └── shabu.longwarp.com.conf   # Nginx proxy config for Shabu Nub Nub
├── systemd/
│   ├── alpha-trader-api.service  # Systemd unit for Python API (Port 8000)
│   ├── alpha-trader-web.service  # Systemd unit for Node Frontend (Port 3000)
│   ├── toll-map.service          # Systemd unit for Toll Map (Port 3001)
│   └── shabu.service             # Systemd unit for Shabu Nub Nub (Port 3002)
├── spec.md                       # Infrastructure specification requirements
└── README.md                     # Deployment guide & operational documentation
```

---

## 🚀 Server Setup & Deployment Guide

Follow these steps on the target Ubuntu Oracle Compute instance:

### 1. Prerequisites & Dependencies

```bash
sudo apt update && sudo apt install -y nginx certbot python3-certbot-nginx apache2-utils git
```

### 2. Directory Setup & Repo Cloning

Clone target repositories into `/var/www/`:

```bash
sudo mkdir -p /var/www
sudo chown -R ubuntu:ubuntu /var/www

cd /var/www
git clone https://github.com/palakons/alpha-trader-v2.git
git clone https://github.com/palakons/thai_unified_toll_map.git
git clone https://github.com/palakons/shabu_nub_nub.git
```

Clone this configuration repo:

```bash
cd /home/ubuntu
git clone https://github.com/palakons/oracle-app-server.git
```

---

### 3. Environment Secrets Setup

Create `.env` files with restricted permissions for each application (secrets are kept outside Git):

```bash
# Example for alpha-trader-v2 backend
touch /var/www/alpha-trader-v2/backend/.env
chmod 600 /var/www/alpha-trader-v2/backend/.env

# Example for alpha-trader-v2 frontend
touch /var/www/alpha-trader-v2/frontend/.env
chmod 600 /var/www/alpha-trader-v2/frontend/.env

# Repeat for toll map & shabu nub nub as required
```

---

### 4. Basic Authentication Setup (`trade.longwarp.com`)

Generate `.htpasswd` for restricting access to `trade.longwarp.com`:

```bash
sudo htpasswd -c /etc/nginx/.htpasswd admin
# Enter a strong password when prompted
```

---

### 5. Systemd Services Setup

Copy service units to `/etc/systemd/system/`, reload daemon, and start services:

```bash
sudo cp /home/ubuntu/oracle-app-server/systemd/*.service /etc/systemd/system/
sudo systemctl daemon-reload

# Enable & start all services
sudo systemctl enable --now alpha-trader-api.service
sudo systemctl enable --now alpha-trader-web.service
sudo systemctl enable --now toll-map.service
sudo systemctl enable --now shabu.service

# Verify service status
sudo systemctl status alpha-trader-api alpha-trader-web toll-map shabu
```

---

### 6. Nginx Proxy Setup & SSL Certificates

Copy virtual host configurations and enable sites:

```bash
sudo cp /home/ubuntu/oracle-app-server/nginx/*.conf /etc/nginx/sites-available/
sudo ln -sf /etc/nginx/sites-available/*.conf /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
```

Obtain SSL certificates using Certbot:

```bash
sudo certbot --nginx -d trade.longwarp.com -d toll.longwarp.com -d shabu.longwarp.com
```

Test and reload Nginx:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

### 7. Firewall & Security Configuration

Ensure iptables / UFW and Oracle Cloud Ingress Rules permit traffic on SSH, HTTP, and HTTPS:

```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

---

## 🔄 Updating Server Configuration

When changes are pushed to `oracle-app-server` on GitHub, update the server by running:

```bash
cd /home/ubuntu/oracle-app-server
git pull origin main

# Update systemd services if changed
sudo cp systemd/*.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl restart alpha-trader-api alpha-trader-web toll-map shabu

# Update Nginx configs if changed
sudo cp nginx/*.conf /etc/nginx/sites-available/
sudo nginx -t && sudo systemctl reload nginx
```
