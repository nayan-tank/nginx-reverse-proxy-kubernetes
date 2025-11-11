# Load Balancing with NGINX 

Load balancing with **Nginx** means distributing incoming traffic across multiple backend servers to improve performance, reliability, and scalability. Nginx can act as a **reverse proxy** that routes requests to a pool of servers using different load-balancing algorithms.

Here’s a step-by-step guide 👇

---

## 🧩 1. Basic Architecture

```
        ┌──────────────┐
        │   Clients    │
        └──────┬───────┘
               │
        ┌──────▼───────┐
        │   NGINX LB   │
        └──────┬───────┘
         ┌──────┴───────┐
         │               │
 ┌───────▼──────┐ ┌──────▼──────┐
 │  app-server1 │ │ app-server2 │
 └───────────────┘ └────────────┘
```

---

## ⚙️ 2. Basic Nginx Load Balancer Configuration

Edit your Nginx configuration (e.g., `/etc/nginx/nginx.conf` or a file under `/etc/nginx/conf.d/`):

```nginx
http {
    upstream backend {
        server 192.168.1.101;
        server 192.168.1.102;
        server 192.168.1.103;
    }

    server {
        listen 80;

        location / {
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
}
```

✅ **Explanation:**

* `upstream backend {}` defines a group of backend servers.
* `proxy_pass http://backend;` sends client requests to that group.
* Nginx automatically distributes requests across the listed servers (default = **round-robin**).

---

## ⚖️ 3. Load Balancing Methods

You can specify different algorithms in the `upstream` block:

| Method                    | Description                                                    | Example                                               |
| ------------------------- | -------------------------------------------------------------- | ----------------------------------------------------- |
| **Round Robin (default)** | Requests are distributed evenly                                | `server backend1; server backend2;`                   |
| **Least Connections**     | Sends traffic to the server with the fewest active connections | `least_conn;`                                         |
| **IP Hash**               | Clients with the same IP always reach the same backend         | `ip_hash;`                                            |
| **Weighted Round Robin**  | Prioritize faster/more powerful servers                        | `server backend1 weight=3; server backend2 weight=1;` |
| **Hash (for custom key)** | Use a variable (like user ID) to determine routing             | `hash $request_uri consistent;`                       |

Example:

```nginx
upstream backend {
    least_conn;
    server 192.168.1.101;
    server 192.168.1.102;
}
```

---

## 🚦 4. Health Checks (Basic)

You can use `max_fails` and `fail_timeout`:

```nginx
upstream backend {
    server 192.168.1.101 max_fails=3 fail_timeout=30s;
    server 192.168.1.102 max_fails=3 fail_timeout=30s;
}
```

If a backend fails 3 times within 30s, Nginx marks it as **unavailable** temporarily.

---

## 🔒 5. SSL + Proxy Example

If your Nginx also handles HTTPS:

```nginx
server {
    listen 443 ssl;
    server_name example.com;

    ssl_certificate /etc/nginx/ssl/example.crt;
    ssl_certificate_key /etc/nginx/ssl/example.key;

    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## 🧠 6. Optional: Enable Sticky Sessions (Session Persistence)

Use the **`ip_hash`** directive or a plugin like **nginx-sticky-module** if you need users to consistently hit the same backend.

Example with `ip_hash`:

```nginx
upstream backend {
    ip_hash;
    server 192.168.1.101;
    server 192.168.1.102;
}
```

---

## 🧰 7. Verify & Reload

After editing:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## 📊 8. Monitoring

You can monitor traffic and load balancing with:

* `stub_status` module
* Tools like **Grafana + Prometheus + Nginx Exporter**
* Logs in `/var/log/nginx/access.log`

---


---

# Real World Scenario

**production-ready Nginx load balancer** setup — suitable for real web apps (Node.js, Python, Java, etc.) with **health checks**, **sticky sessions**, and **failover handling**.

---

## 🧩 Architecture Overview

```
                   ┌────────────┐
                   │   Clients  │
                   └──────┬─────┘
                          │
                    ┌──────▼──────┐
                    │   NGINX LB  │  ← Reverse Proxy + SSL + Load Balancing
                    └──────┬──────┘
             ┌─────────────┴─────────────┐
             │                           │
      ┌──────▼──────┐             ┌──────▼──────┐
      │  app-server1│             │  app-server2│
      └──────────────┘             └────────────┘
```

---

## ⚙️ Full Nginx Configuration (`/etc/nginx/conf.d/load-balancer.conf`)

```nginx
# ============================================
# Production-Grade Load Balancer Configuration
# ============================================

# Define upstream (backend) servers
upstream backend_cluster {
    # Load balancing method: least connections
    least_conn;

    # Server definitions with failover and weights
    server 10.0.0.101:8080 max_fails=3 fail_timeout=30s weight=2;
    server 10.0.0.102:8080 max_fails=3 fail_timeout=30s weight=2;
    server 10.0.0.103:8080 backup;  # Failover (backup) server
}

# HTTP to HTTPS redirection
server {
    listen 80;
    server_name example.com www.example.com;
    return 301 https://$host$request_uri;
}

# HTTPS load balancer
server {
    listen 443 ssl http2;
    server_name example.com www.example.com;

    # SSL certificates
    ssl_certificate     /etc/ssl/certs/example.crt;
    ssl_certificate_key /etc/ssl/private/example.key;

    # Recommended SSL settings (production)
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Enable gzip compression for responses
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # Real IP forwarding
    real_ip_header X-Forwarded-For;
    set_real_ip_from 0.0.0.0/0;

    location / {
        proxy_pass http://backend_cluster;

        # Preserve client info
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Timeouts
        proxy_connect_timeout 10s;
        proxy_read_timeout 60s;
        proxy_send_timeout 60s;

        # Cache control (optional)
        proxy_cache_bypass $http_upgrade;

        # Sticky sessions using cookie (manual method)
        # Uncomment if you use sticky module
        # sticky cookie srv_id expires=1h domain=.example.com path=/;

        # Optional: health check endpoint (for apps that support /health)
        proxy_next_upstream error timeout http_502 http_503 http_504;
    }

    # Health check endpoint (optional)
    location /nginx_status {
        stub_status;
        allow 127.0.0.1;
        deny all;
    }

    # Static error pages
    error_page 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
```

---

## 🧠 Key Highlights

| Feature                      | Purpose                                                                                    |
| ---------------------------- | ------------------------------------------------------------------------------------------ |
| `least_conn;`                | Balances load based on the number of active connections (best for persistent connections). |
| `backup;`                    | Defines a standby server for failover.                                                     |
| `max_fails` / `fail_timeout` | Marks unhealthy servers temporarily unavailable.                                           |
| HTTPS + HTTP2                | Secure and modern transport.                                                               |
| `stub_status`                | Exposes internal metrics for monitoring.                                                   |
| `gzip`                       | Compresses responses to improve performance.                                               |
| Sticky session (optional)    | Keeps a user on the same backend server.                                                   |

---

## 🩺 Health Check Setup

If your backend app exposes a `/health` endpoint, you can use **`proxy_next_upstream`** to reroute failed requests automatically.

Alternatively, install **`nginx-plus`** or a **third-party health check module** for active probing.

Example passive check logic:

```nginx
proxy_next_upstream error timeout invalid_header http_502 http_503 http_504;
```

---

## 🧰 Testing & Reloading

```bash
sudo nginx -t          # Test syntax
sudo systemctl reload nginx   # Reload config safely
```

Test the load balancing:

```bash
curl -I https://example.com
```

You can verify backend routing by adding a debug header in your backend app (like `X-Server-ID`).

---

## 📊 Optional: Monitor Traffic

Enable status metrics:

```bash
curl http://localhost/nginx_status
```

Output example:

```
Active connections: 12 
server accepts handled requests
  1023 1023 2456 
Reading: 2 Writing: 5 Waiting: 5
```

Integrate with:

* **Prometheus + nginx-exporter**
* **Grafana dashboards**

---
