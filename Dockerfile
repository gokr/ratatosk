# Ratatosk: one image holding the server and the built web app.
#
# The web app is compiled here rather than copied in, so the image is
# reproducible from the repository alone — no "remember to run flutter build
# first" step that silently ships a stale or missing UI.
#
#   docker build -t ratatosk .
#   docker run -d -v ratatosk-data:/var/lib/ratatosk -p 8080:8080 ratatosk

# --- the web app ----------------------------------------------------------
FROM ghcr.io/cirruslabs/flutter:stable AS web
WORKDIR /src
# Dependencies first: this layer is reused until pubspec actually changes.
COPY app/pubspec.yaml app/pubspec.lock ./
RUN flutter pub get
COPY app/ ./
RUN flutter build web --release

# --- the server -----------------------------------------------------------
FROM golang:1.26-bookworm AS server
WORKDIR /src
COPY server/go.mod server/go.sum ./
RUN go mod download
COPY server/ ./
# Static, so the runtime image needs no libc to match.
RUN CGO_ENABLED=0 go build -trimpath -ldflags "-s -w" -o /out/ratatoskd ./cmd/ratatoskd

# --- runtime --------------------------------------------------------------
FROM debian:bookworm-slim AS runtime

# Web Push makes outbound TLS calls, so the CA bundle is required; tzdata keeps
# timestamps readable in logs; sqlite3 is absent on purpose (the binary embeds
# its own SQLite).
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates tzdata \
 && rm -rf /var/lib/apt/lists/*

# A fixed unprivileged uid/gid. The data directory is created here, owned by it:
# Docker seeds a *new* named volume with this directory's ownership, which is
# what makes the first write work without running as root.
RUN groupadd --gid 10001 ratatosk \
 && useradd --uid 10001 --gid 10001 --no-create-home --shell /usr/sbin/nologin ratatosk \
 && install -d -o ratatosk -g ratatosk -m 0700 /var/lib/ratatosk \
 && install -d -o root -g root -m 0755 /usr/share/ratatosk

COPY --from=server /out/ratatoskd /usr/local/bin/ratatoskd
COPY --from=web /src/build/web /usr/share/ratatosk/web

USER ratatosk

# The database, its WAL and the uploaded blobs all live here. Mount a volume
# (or a host path) at this exact path or every restart starts empty.
VOLUME ["/var/lib/ratatosk"]

ENV RATATOSK_DATA=/var/lib/ratatosk \
    RATATOSK_WEB_DIR=/usr/share/ratatosk/web \
    RATATOSK_ADDR=:8080

EXPOSE 8080

# A real probe, not just "is the binary present": the server asks its own
# /healthz (the image has no curl), so a wedged process is reported unhealthy.
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD ["/usr/local/bin/ratatoskd", "-healthcheck", "--addr", "127.0.0.1:8080"]

ENTRYPOINT ["/usr/local/bin/ratatoskd"]
CMD ["--addr", ":8080", "--data", "/var/lib/ratatosk", "--web", "/usr/share/ratatosk/web"]
