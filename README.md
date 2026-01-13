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

- `CADDY_INGRESS_NETWORKS` - Comma-separated list of Docker networks to use (default: all networks)
- `CADDY_DOCKER_EXPOSEDBYDEFAULT` - Whether to expose containers without labels (default: `true`)
- `CADDY_DOCKER_LABEL_PREFIX` - Label prefix to look for (default: `caddy`)
- `CADDY_DOCKER_POLLINGINTERVAL` - How often to poll Docker for changes (default: `30s`)

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
