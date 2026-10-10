// Command ratatoskd is the Ratatosk chat server: a Connect (gRPC/HTTP) API for
// accounts, conversations, messages and invitations, plus the small number of
// plain HTTP endpoints a browser needs (attachment downloads and invite links).
//
//	go run ./cmd/ratatoskd --addr :8080 --data ./data
//
// Configuration comes from flags, with every flag also readable from the
// environment so the binary works unchanged in a container.
package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/gokr/ratatosk/server/internal/httpserver"
	"github.com/gokr/ratatosk/server/internal/realtime"
	"github.com/gokr/ratatosk/server/internal/service"
	"github.com/gokr/ratatosk/server/internal/store"
)

// version is stamped at build time with -ldflags "-X main.version=…".
var version = "dev"

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "ratatoskd:", err)
		os.Exit(1)
	}
}

type options struct {
	addr            string
	dataDir         string
	publicURL       string
	corsOrigins     string
	deepLinkScheme  string
	sessionTTL      time.Duration
	inviteTTL       time.Duration
	inviteMaxUses   int
	maxUploadBytes  int64
	presenceTimeout time.Duration
	logLevel        string
	logFormat       string
}

func run() error {
	var o options
	flag.StringVar(&o.addr, "addr", env("RATATOSK_ADDR", ":8080"), "address to listen on")
	flag.StringVar(&o.dataDir, "data", env("RATATOSK_DATA", "./data"), "directory holding the database and uploaded files")
	flag.StringVar(&o.publicURL, "public-url", env("RATATOSK_PUBLIC_URL", ""), "public origin used in invite links (default http://<addr>)")
	flag.StringVar(&o.corsOrigins, "cors-origins", env("RATATOSK_CORS_ORIGINS", "*"), "comma-separated browser origins allowed to call the API, or * for any")
	flag.StringVar(&o.deepLinkScheme, "deeplink-scheme", env("RATATOSK_DEEPLINK_SCHEME", "ratatosk"), "URI scheme the mobile apps register for invite links")
	flag.DurationVar(&o.sessionTTL, "session-ttl", envDuration("RATATOSK_SESSION_TTL", 30*24*time.Hour), "how long a login lasts")
	flag.DurationVar(&o.inviteTTL, "invite-ttl", envDuration("RATATOSK_INVITE_TTL", 7*24*time.Hour), "default lifetime of a new invite link (0 for no expiry)")
	flag.IntVar(&o.inviteMaxUses, "invite-max-uses", envInt("RATATOSK_INVITE_MAX_USES", 1), "default number of uses for a new invite link (0 for unlimited)")
	flag.Int64Var(&o.maxUploadBytes, "max-upload-bytes", int64(envInt("RATATOSK_MAX_UPLOAD_BYTES", 8<<20)), "largest accepted attachment")
	flag.DurationVar(&o.presenceTimeout, "away-after", envDuration("RATATOSK_AWAY_AFTER", 5*time.Minute), "idle time after which a connected user counts as away")
	flag.StringVar(&o.logLevel, "log-level", env("RATATOSK_LOG_LEVEL", "info"), "debug, info, warn or error")
	flag.StringVar(&o.logFormat, "log-format", env("RATATOSK_LOG_FORMAT", "text"), "text or json")
	showVersion := flag.Bool("version", false, "print the version and exit")
	flag.Parse()

	if *showVersion {
		fmt.Println("ratatoskd", version)
		return nil
	}

	log := newLogger(o.logLevel, o.logFormat)
	slog.SetDefault(log)

	publicURL, err := resolvePublicURL(o.publicURL, o.addr)
	if err != nil {
		return err
	}

	st, err := store.Open(o.dataDir, log)
	if err != nil {
		return err
	}
	defer func() {
		if err := st.Close(); err != nil {
			log.Error("store close failed", "err", err)
		}
	}()

	hub := realtime.NewHub()
	presence := realtime.NewTracker(st, hub, nil, o.presenceTimeout, log)

	cfg := service.DefaultConfig()
	cfg.PublicURL = publicURL
	cfg.SessionTTL = o.sessionTTL
	cfg.InviteTTL = o.inviteTTL
	cfg.InviteMaxUses = o.inviteMaxUses
	cfg.MaxUploadBytes = o.maxUploadBytes
	services := service.New(st, hub, presence, cfg, log)

	handler := httpserver.New(httpserver.Config{
		Addr:           o.addr,
		PublicURL:      publicURL,
		CORSOrigins:    splitOrigins(o.corsOrigins),
		DeepLinkScheme: o.deepLinkScheme,
		Log:            log,
	}, st, hub, presence, services)

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	go presence.Run(ctx)

	srv := &http.Server{
		Addr:              o.addr,
		Handler:           handler,
		ReadHeaderTimeout: 10 * time.Second,
		// No write timeout: the Subscribe stream is long-lived by design, and a
		// deadline here would silently kill every connected client.
		IdleTimeout: 120 * time.Second,
		BaseContext: func(net.Listener) context.Context { return ctx },
	}

	errc := make(chan error, 1)
	go func() {
		log.Info("ratatosk listening",
			"addr", o.addr, "publicUrl", publicURL, "data", o.dataDir, "version", version)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			errc <- err
		}
	}()

	select {
	case err := <-errc:
		return err
	case <-ctx.Done():
		log.Info("shutting down")
	}
	// Give in-flight requests a moment, then persist and stop.
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Warn("graceful shutdown timed out", "err", err)
	}
	return nil
}

// resolvePublicURL is the origin handed to clients in invite and attachment
// links. When it is not configured we guess from the listen address, which is
// right for local development and wrong behind a proxy — hence the flag.
func resolvePublicURL(configured, addr string) (string, error) {
	if configured != "" {
		return strings.TrimRight(configured, "/"), nil
	}
	host, port, err := net.SplitHostPort(addr)
	if err != nil {
		return "", fmt.Errorf("invalid --addr %q: %w", addr, err)
	}
	if host == "" || host == "0.0.0.0" || host == "::" {
		host = "localhost"
	}
	return "http://" + net.JoinHostPort(host, port), nil
}

func splitOrigins(raw string) []string {
	if strings.TrimSpace(raw) == "" {
		return nil
	}
	parts := strings.Split(raw, ",")
	out := make([]string, 0, len(parts))
	for _, p := range parts {
		if p = strings.TrimSpace(p); p != "" {
			out = append(out, p)
		}
	}
	return out
}

func newLogger(level, format string) *slog.Logger {
	var lvl slog.Level
	switch strings.ToLower(level) {
	case "debug":
		lvl = slog.LevelDebug
	case "warn":
		lvl = slog.LevelWarn
	case "error":
		lvl = slog.LevelError
	default:
		lvl = slog.LevelInfo
	}
	opts := &slog.HandlerOptions{Level: lvl}
	var h slog.Handler
	if strings.EqualFold(format, "json") {
		h = slog.NewJSONHandler(os.Stdout, opts)
	} else {
		h = slog.NewTextHandler(os.Stdout, opts)
	}
	return slog.New(h)
}

func env(key, fallback string) string {
	if v, ok := os.LookupEnv(key); ok && v != "" {
		return v
	}
	return fallback
}

func envInt(key string, fallback int) int {
	if v, ok := os.LookupEnv(key); ok && v != "" {
		var n int
		if _, err := fmt.Sscanf(v, "%d", &n); err == nil {
			return n
		}
	}
	return fallback
}

func envDuration(key string, fallback time.Duration) time.Duration {
	if v, ok := os.LookupEnv(key); ok && v != "" {
		if d, err := time.ParseDuration(v); err == nil {
			return d
		}
	}
	return fallback
}
