# syntax=docker/dockerfile:1.4
FROM caddy:2-builder AS builder

# Set environment variables for Go cache
ENV GOCACHE=/root/.cache/go-build
ENV GOMODCACHE=/go/pkg/mod
ENV XCADDY_GO_BUILD_FLAGS=-ldflags=-linkmode=external

# Build Caddy with plugins using cache mounts for faster builds
RUN --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/go/pkg/mod \
    xcaddy build \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/mholt/caddy-l4 \
    --with github.com/lucaslorentz/caddy-docker-proxy/v2 

# Final stage
FROM caddy:2-alpine

# Copy caddy binary from builder
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
