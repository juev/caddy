FROM caddy:2-builder AS builder

# Build Caddy with plugins
RUN xcaddy build \
    --with github.com/mholt/caddy-webdav \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/mholt/caddy-l4

# Final stage
FROM caddy:2-alpine

# Copy caddy binary from builder
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
