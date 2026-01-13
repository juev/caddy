# Custom Caddy Docker Image

[![Build and Push Caddy Docker Images](https://github.com/juev/caddy/actions/workflows/docker-build.yml/badge.svg)](https://github.com/juev/caddy/actions/workflows/docker-build.yml)

Custom Caddy build with additional plugins for enhanced functionality.

## Features

This Docker image includes Caddy web server with the following plugins:

- **[caddy-dns/cloudflare](https://github.com/caddy-dns/cloudflare)** - Cloudflare DNS provider for automatic HTTPS
- **[mholt/caddy-l4](https://github.com/mholt/caddy-l4)** - Layer 4 (TCP/UDP) app for Caddy
- **[caddy-docker-proxy](https://github.com/lucaslorentz/caddy-docker-proxy)** - Automatic proxy configuration from Docker containers

## Quick Start

### Pull from GitHub Container Registry

```bash
docker pull ghcr.io/juev/caddy:latest
```

### Run with default configuration

```bash
docker run -d \
  --name caddy \
  -p 80:80 \
  -p 443:443 \
  ghcr.io/juev/caddy:latest
```

### Run with custom Caddyfile

```bash
docker run -d \
  --name caddy \
  -p 80:80 \
  -p 443:443 \
  -v /path/to/your/Caddyfile:/etc/caddy/Caddyfile \
  -v /path/to/data:/data \
  -v /path/to/config:/config \
  ghcr.io/juev/caddy:latest
```

## Configuration

### Volumes

- `/data` - Caddy data directory (automatic HTTPS certificates, etc.)
- `/config` - Caddy configuration directory
- `/etc/caddy/Caddyfile` - Main configuration file
- `/srv` - Default web root directory

### Ports

- `80` - HTTP
- `443` - HTTPS
- `2019` - Admin API (optional)

## Plugin Usage Examples

### Cloudflare DNS

You can configure Cloudflare DNS for automatic HTTPS certificates in two ways:

**Global configuration** (applies to all sites):

```caddyfile
{
    acme_dns cloudflare {env.CLOUDFLARE_API_TOKEN}
}

example.com {
    respond "Hello, World!"
}
```

**Per-site configuration**:

```caddyfile
example.com {
    tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
    }
    respond "Hello, World!"
}
```

The global `acme_dns` configuration is recommended when using multiple sites with Cloudflare DNS, as it avoids repeating the configuration for each site.

### Layer4

```caddyfile
{
    layer4 {
        :22 {
            route {
                proxy forgejo:22
            }
        }
    }
}
```

### Docker Proxy with Cloudflare DNS

Example Caddyfile with global Cloudflare DNS configuration for automatic HTTPS:

```caddyfile
{
    # Global ACME configuration with Cloudflare DNS
    acme_dns cloudflare {env.CLOUDFLARE_API_TOKEN}
}
```

Example `docker-compose.yml` with environment variables and labels for automatic upstream configuration:

```yaml
version: '3.8'

services:
  caddy:
    image: ghcr.io/juev/caddy:latest
    container_name: caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      - CLOUDFLARE_API_TOKEN=your_cloudflare_api_token_here
      # Docker proxy configuration via environment variables
      - CADDY_DOCKER_CADDYFILE_PATH=/etc/caddy/Caddyfile
      - CADDY_INGRESS_NETWORKS=caddy-network
      - CADDY_DOCKER_EXPOSEDBYDEFAULT=false
    networks:
      - caddy-network

  app:
    image: nginx:alpine
    container_name: my-app
    labels:
      caddy: example.com
      caddy.reverse_proxy: "{{upstreams 80}}"
    networks:
      - caddy-network

volumes:
  caddy_data:
  caddy_config:

networks:
  caddy-network:
    driver: bridge
```

With these labels and environment variables, Caddy will automatically:

- Configure `example.com` to proxy to the `app` container
- Use the global Cloudflare DNS configuration (`acme_dns`) for automatic HTTPS certificate generation
- Update configuration when the container starts/stops
- Only expose containers with `caddy` labels (due to `CADDY_DOCKER_EXPOSEDBYDEFAULT=false`)
- Use the `caddy-network` for container discovery (via `CADDY_INGRESS_NETWORKS`)

**Available environment variables for caddy-docker-proxy:**

- `CADDY_DOCKER_CADDYFILE_PATH` - Path to Caddyfile with global options
- `CADDY_INGRESS_NETWORKS` - Comma-separated list of Docker networks to use (default: all networks)
- `CADDY_DOCKER_EXPOSEDBYDEFAULT` - Whether to expose containers without labels (default: `true`)
- `CADDY_DOCKER_LABEL_PREFIX` - Label prefix to look for (default: `caddy`)
- `CADDY_DOCKER_POLLINGINTERVAL` - How often to poll Docker for changes (default: `30s`)

### Troubleshooting: Containers from Other Compose Files Not Discovered

If Caddy is not discovering containers from other `docker-compose.yml` files, check the following:

#### 1. **Shared Docker Network** (Most Common Issue)

All containers that need to be proxied must be on the same Docker network as Caddy. Use an **external network**:

**Step 1:** Create a shared network:

```bash
docker network create caddy-network
```

**Step 2:** In your Caddy `docker-compose.yml`:

```yaml
networks:
  caddy-network:
    external: true
```

**Step 3:** In your other `docker-compose.yml` files, use the same external network:

```yaml
services:
  your-app:
    labels:
      caddy: app.example.com
      caddy.reverse_proxy: "{{upstreams 80}}"
    networks:
      - caddy-network

networks:
  caddy-network:
    external: true
```

#### 2. **CADDY_INGRESS_NETWORKS Configuration**

If you're using specific networks, make sure `CADDY_INGRESS_NETWORKS` includes all networks where your containers are running:

```yaml
environment:
  # List all networks separated by commas
  - CADDY_INGRESS_NETWORKS=caddy-network,app-network,other-network
  
  # OR leave empty to monitor all networks (may be slower)
  - CADDY_INGRESS_NETWORKS=
```

#### 3. **Docker Socket Access**

Ensure Docker socket is mounted (read-only for security):

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock:ro
```

#### 4. **Caddyfile Configuration**

When using `caddy docker-proxy`, your Caddyfile should contain **only global options**. Domain-specific configuration comes from Docker labels:

```caddyfile
{
    # Global settings only (e.g., acme_dns)
    acme_dns cloudflare {env.CLOUDFLARE_API_TOKEN}
}

# Static sites can still be defined here
nas.example.com {
    # Static configuration
}
```

**Do NOT** define domains in Caddyfile that should be managed by docker-proxy labels - this will cause conflicts.

#### 5. **Label Format**

Ensure labels are correctly formatted in your other compose files:

```yaml
services:
  your-app:
    labels:
      # Domain name
      caddy: app.example.com
      
      # Reverse proxy configuration
      caddy.reverse_proxy: "{{upstreams 80}}"
      
      # Optional: Additional Caddy directives
      caddy.tls: "internal"
      caddy.rewrite: "/api/* /api/*"
```

#### 6. **Verify Container Discovery**

Check if Caddy can see your containers:

```bash
# Check Caddy logs
docker logs caddy

# Verify containers are on the same network
docker network inspect caddy-network

# Check if containers have correct labels
docker inspect <container-name> | grep -A 10 Labels
```

#### 7. **Complete Example Setup**

**Caddy compose file (`caddy-compose.yml`):**

```yaml
version: '3.8'
services:
  caddy:
    image: ghcr.io/juev/caddy:latest
    container_name: caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      - CADDY_INGRESS_NETWORKS=
      - CADDY_DOCKER_EXPOSEDBYDEFAULT=false
    networks:
      - caddy-network

networks:
  caddy-network:
    external: true
```

**Other service compose file (`app-compose.yml`):**

```yaml
version: '3.8'
services:
  app:
    image: nginx:alpine
    container_name: my-app
    labels:
      caddy: app.example.com
      caddy.reverse_proxy: "{{upstreams 80}}"
    networks:
      - caddy-network

networks:
  caddy-network:
    external: true
```

**Start both:**

```bash
# Create network first
docker network create caddy-network

# Start Caddy
docker-compose -f caddy-compose.yml up -d

# Start your app
docker-compose -f app-compose.yml up -d
```

## Building Locally

```bash
git clone https://github.com/juev/caddy.git
cd caddy
docker build -t custom-caddy .
```

## Image Tags

- `latest` - Latest build from main branch
- `v*` - Specific version tags
- `YYYYMMDD` - Weekly automated builds

## Multi-Architecture Support

Images are built for:

- `linux/amd64`
- `linux/arm64`

## Security

This image runs as non-root user `caddy` (UID: 1001) for enhanced security.

## Health Check

The image includes a health check that validates the Caddyfile configuration.

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the original [Caddy license](https://github.com/caddyserver/caddy/blob/master/LICENSE) for details.

## Links

- [Caddy Documentation](https://caddyserver.com/docs/)
- [GitHub Container Registry](https://github.com/juev/caddy/pkgs/container/caddy)
- [Docker Hub](https://hub.docker.com/r/juev/caddy) (if applicable)

## Support

For issues related to:

- Caddy core functionality: [Caddy Community Forum](https://caddy.community/)
- This custom build: [GitHub Issues](https://github.com/juev/caddy/issues)
- Plugin-specific issues: Refer to respective plugin repositories
