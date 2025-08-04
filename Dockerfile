FROM golang:alpine AS builder

# Install git and ca-certificates
RUN apk --no-cache add git ca-certificates

# Install xcaddy
RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

# Build Caddy with plugins
RUN xcaddy build \
    --with github.com/mholt/caddy-webdav \
    --with github.com/tailscale/caddy-tailscale \
    --with github.com/caddy-dns/cloudflare

# Final stage
FROM alpine:latest

# Install ca-certificates for HTTPS
RUN apk --no-cache add ca-certificates

# Create caddy user
RUN addgroup -g 1001 -S caddy \
    && adduser -u 1001 -D -S -G caddy caddy

# Copy caddy binary from builder
COPY --from=builder /go/caddy /usr/bin/caddy

# Copy default Caddyfile (will be created if doesn't exist)
COPY --chown=caddy:caddy Caddyfile /etc/caddy/Caddyfile

# Create necessary directories
RUN mkdir -p /var/lib/caddy /var/log/caddy /etc/caddy \
    && chown -R caddy:caddy /var/lib/caddy /var/log/caddy /etc/caddy

# Switch to caddy user
USER caddy

# Expose ports
EXPOSE 80 443 2019

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD caddy validate --config /etc/caddy/Caddyfile || exit 1

# Set working directory
WORKDIR /srv

# Default command
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]