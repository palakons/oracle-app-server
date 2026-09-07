# Oracle App Server Deployment Guide

Detailed step-by-step instructions for setting up systemd services, application repositories, Nginx reverse proxy, and SSL certificates on an Ubuntu Oracle Compute instance.

---

## 📌 Application Architecture & Port Mapping

| Domain | Application | Target Directory | Internal Port | Security |
|---|---|---|---|---|
| `trade.longwarp.com` | Alpha Trader v2 (Web) | `/var/www/alpha-trader-v2/frontend` | `3000` | Basic Auth over HTTPS |
| `trade.longwarp.com` | Alpha Trader v2 (API) | `/var/www/alpha-trader-v2/backend` | `8000` | Basic Auth over HTTPS |
| `toll.longwarp.com` | Thai Unified Toll Map | `/var/www/thai_unified_toll_map` | `3001` | Public HTTPS |
| `shabu.longwarp.com` | Shabu Nub Nub | `/var/www/shabu_nub_nub` | `3002` | Public HTTPS |

---

## 🚀 Step 1: Install Required Dependencies

Update package lists and install Nginx, Certbot, Apache utilities, Git, and Python venv tools:

```bash
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx apache2-utils git python3-venv nodejs npm
```

---

## 📁 Step 2: Prepare Application Directories & Clone Repositories

Create `/var/www` directory owned by user `ubuntu`:

```bash
sudo mkdir -p /var/www
sudo chown -R ubuntu:ubuntu /var/www
```

Clone the 3 application repositories into `/var/www/`:

```bash
cd /var/www
git clone https://github.com/palakons/alpha-trader-v2.git
git clone https://github.com/palakons/thai_unified_toll_map.git
git clone https://github.com/palakons/shabu_nub_nub.git
```

---

## 🔐 Step 3: Configure Secrets and Environment Files

Create `.env` files for each application and restrict permissions so secrets remain safe:

```bash
# Alpha Trader Backend
touch /var/www/alpha-trader-v2/backend/.env
chmod 600 /var/www/alpha-trader-v2/backend/.env

# Alpha Trader Frontend
touch /var/www/alpha-trader-v2/frontend/.env
chmod 600 /var/www/alpha-trader-v2/frontend/.env

# Thai Unified Toll Map
touch /var/www/thai_unified_toll_map/.env
chmod 600 /var/www/thai_unified_toll_map/.env

# Shabu Nub Nub
touch /var/www/shabu_nub_nub/.env
chmod 600 /var/www/shabu_nub_nub/.env
```

*Populate each `.env` file with any required environment variables (e.g., API keys, database URLs).*

---

## 🛠️ Step 4: Install & Enable Systemd Services

1. Copy service files from the repository to `/etc/systemd/system/`:

```bash
sudo cp /home/ubuntu/oracle-app-server/systemd/*.service /etc/systemd/system/
```

2. Reload systemd configuration:

```bash
sudo systemctl daemon-reload
```

3. Enable services to automatically launch on boot and start them now:

```bash
sudo systemctl enable --now alpha-trader-api.service
sudo systemctl enable --now alpha-trader-web.service
sudo systemctl enable --now toll-map.service
sudo systemctl enable --now shabu.service
```

4. Verify that all 4 systemd services are active and running:

```bash
sudo systemctl status alpha-trader-api alpha-trader-web toll-map shabu
```

---

## 🔒 Step 5: Configure Nginx & Basic Authentication

1. Create HTTP Basic Authentication file for `trade.longwarp.com`:

```bash
sudo htpasswd -c /etc/nginx/.htpasswd admin
# Enter your desired password when prompted
```

2. Copy Nginx site configurations and enable them:

```bash
sudo cp /home/ubuntu/oracle-app-server/nginx/*.conf /etc/nginx/sites-available/
sudo ln -sf /etc/nginx/sites-available/*.conf /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
```

3. Test Nginx syntax:

```bash
sudo nginx -t
```

---

## 🌐 Step 6: Obtain SSL Certificates (Certbot) & Enable HTTPS

> **Prerequisite:** Ensure DNS `A` records for `toll.longwarp.com`, `shabu.longwarp.com`, and `trade.longwarp.com` are pointed to your server's public IP address.

Obtain Let's Encrypt certificates:

```bash
sudo certbot --nginx -d trade.longwarp.com -d toll.longwarp.com -d shabu.longwarp.com
```

Reload Nginx to apply changes:

```bash
sudo systemctl reload nginx
```

---

## 🛡️ Step 7: Firewall Configuration

Ensure UFW and Oracle Cloud Ingress Rules permit HTTP (80) and HTTPS (443):

```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

---

## 🔍 Step 8: Verification & Monitoring Commands

- **Check Service Logs**:
  ```bash
  journalctl -u alpha-trader-api -f
  journalctl -u alpha-trader-web -f
  journalctl -u toll-map -f
  journalctl -u shabu -f
  ```

- **Restart a specific service**:
  ```bash
  sudo systemctl restart toll-map
  ```
