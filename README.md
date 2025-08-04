# Custom Caddy Docker Image

[![Build and Push Caddy Docker Images](https://github.com/juev/caddy/actions/workflows/docker-build.yml/badge.svg)](https://github.com/juev/caddy/actions/workflows/docker-build.yml)

Custom Caddy build with additional plugins for enhanced functionality.

## Features

This Docker image includes Caddy web server with the following plugins:

- **[caddy-webdav](https://github.com/mholt/caddy-webdav)** - WebDAV server functionality
- **[caddy-tailscale](https://github.com/tailscale/caddy-tailscale)** - Tailscale integration for secure networking
- **[caddy-dns/cloudflare](https://github.com/caddy-dns/cloudflare)** - Cloudflare DNS provider for automatic HTTPS

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

### Environment Variables

- `CADDY_CONFIG_PATH` - Path to Caddyfile (default: `/etc/caddy/Caddyfile`)

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

### WebDAV Server

```caddyfile
webdav.example.com {
    webdav {
        root /srv/webdav
    }
    basicauth {
        admin $2a$14$hashed_password_here
    }
}
```

### Tailscale Integration

```caddyfile
{
    servers {
        trusted_proxies tailscale
    }
}

internal.example.ts.net {
    respond "Hello from Tailscale!"
    tailscale_auth
}
```

### Cloudflare DNS

```caddyfile
example.com {
    tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
    }
    respond "Hello, World!"
}
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
