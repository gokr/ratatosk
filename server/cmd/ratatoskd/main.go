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
	"path/filepath"
	"strings"
	"syscall"
	"time"

	"github.com/gokr/ratatosk/server/internal/httpserver"
	"github.com/gokr/ratatosk/server/internal/push"
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
	webDir          string
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
	var log *slog.Logger
	flag.StringVar(&o.addr, "addr", env("RATATOSK_ADDR", ":8080"), "address to listen on")
	flag.StringVar(&o.dataDir, "data", env("RATATOSK_DATA", "./data"), "directory holding the database and uploaded files")
	flag.StringVar(&o.publicURL, "public-url", env("RATATOSK_PUBLIC_URL", ""), "public origin used in invite links (default http://<addr>)")
	flag.StringVar(&o.corsOrigins, "cors-origins", env("RATATOSK_CORS_ORIGINS", "*"), "comma-separated browser origins allowed to call the API, or * for any")
	flag.StringVar(&o.deepLinkScheme, "deeplink-scheme", env("RATATOSK_DEEPLINK_SCHEME", "ratatosk"), "URI scheme the mobile apps register for invite links")
	flag.StringVar(&o.webDir, "web", env("RATATOSK_WEB_DIR", defaultWebDir()), "directory of a built Flutter web app to serve at / (empty to serve no app)")
	flag.DurationVar(&o.sessionTTL, "session-ttl", envDuration("RATATOSK_SESSION_TTL", 30*24*time.Hour), "how long a login lasts")
	flag.DurationVar(&o.inviteTTL, "invite-ttl", envDuration("RATATOSK_INVITE_TTL", 7*24*time.Hour), "default lifetime of a new invite link (0 for no expiry)")
	flag.IntVar(&o.inviteMaxUses, "invite-max-uses", envInt("RATATOSK_INVITE_MAX_USES", 1), "default number of uses for a new invite link (0 for unlimited)")
	flag.Int64Var(&o.maxUploadBytes, "max-upload-bytes", int64(envInt("RATATOSK_MAX_UPLOAD_BYTES", 8<<20)), "largest accepted attachment")
	flag.DurationVar(&o.presenceTimeout, "away-after", envDuration("RATATOSK_AWAY_AFTER", 5*time.Minute), "idle time after which a connected user counts as away")
	flag.StringVar(&o.logLevel, "log-level", env("RATATOSK_LOG_LEVEL", "info"), "debug, info, warn or error")
	flag.StringVar(&o.logFormat, "log-format", env("RATATOSK_LOG_FORMAT", "text"), "text or json")
	showVersion := flag.Bool("version", false, "print the version and exit")
	// A container has no curl and no shell tools by default; the binary probes
	// itself so a HEALTHCHECK needs nothing extra in the image.
	healthcheck := flag.Bool("healthcheck", false, "probe the running server's /healthz and exit (for container health checks)")
	// An operator action, not an RPC: there is no self-service account deletion
	// yet, and a handle plus a password prompt is not a reason to hand-edit
	// encrypted rows. Run it with the server stopped.
	deleteAccount := flag.String("delete-account", "", "delete the named account and its data, then exit (stop the server first)")
	flag.Parse()

	if *showVersion {
		fmt.Println("ratatoskd", version)
		return nil
	}

	log = newLogger(o.logLevel, o.logFormat)
	slog.SetDefault(log)

	if *healthcheck {
		return probeHealth(o.addr)
	}

	// Deletion opens the store itself and returns; it must not race a running
	// server for the database.
	if *deleteAccount != "" {
		return runDeleteAccount(o, *deleteAccount, log)
	}

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

	// Stable, operator-provided VAPID keys: absent disables push; partial
	// configuration fails startup rather than silently rotating subscriptions.
	pushWorker, err := push.New(push.Config{
		PublicKey:  os.Getenv("RATATOSK_VAPID_PUBLIC_KEY"),
		PrivateKey: os.Getenv("RATATOSK_VAPID_PRIVATE_KEY"),
		Contact:    os.Getenv("RATATOSK_VAPID_CONTACT"),
	}, st, nil)
	if err != nil {
		return fmt.Errorf("web push: %w", err)
	}

	hub := realtime.NewHub()
	presence := realtime.NewTracker(st, hub, nil, o.presenceTimeout, log)

	cfg := service.DefaultConfig()
	cfg.MessageNotifier = pushWorker
	cfg.PublicURL = publicURL
	cfg.SessionTTL = o.sessionTTL
	cfg.InviteTTL = o.inviteTTL
	cfg.InviteMaxUses = o.inviteMaxUses
	cfg.MaxUploadBytes = o.maxUploadBytes
	services := service.New(st, hub, presence, cfg, log)

	handler := httpserver.New(httpserver.Config{
		Push:           pushWorker,
		Addr:           o.addr,
		PublicURL:      publicURL,
		CORSOrigins:    splitOrigins(o.corsOrigins),
		DeepLinkScheme: o.deepLinkScheme,
		WebDir:         resolveWebDir(o.webDir),
		Log:            log,
	}, st, hub, presence, services)

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	go presence.Run(ctx)
	pushDone := make(chan struct{})
	go func() { defer close(pushDone); pushWorker.Run(ctx) }()
	defer func() { stop(); <-pushDone }()

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
	webDir := resolveWebDir(o.webDir)
	serves := "no web app (build one with `cd app && flutter build web`)"
	if webDir != "" {
		serves = "web app from " + webDir
	}
	go func() {
		log.Info("ratatosk listening",
			"addr", o.addr, "publicUrl", publicURL, "data", o.dataDir,
			"web", serves, "version", version)
		log.Info("open " + publicURL + " in a browser, or point a client at it")
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

// defaultWebDir is where `flutter build web` puts the app, found relative to
// the working directory first (running from the repository root) and then to
// the binary (running an installed server beside an installed app).
func defaultWebDir() string {
	candidates := []string{
		filepath.Join("app", "build", "web"),
	}
	if exe, err := os.Executable(); err == nil {
		// var/bin/ratatoskd -> the repository root is two levels up.
		root := filepath.Dir(filepath.Dir(filepath.Dir(exe)))
		candidates = append(candidates, filepath.Join(root, "app", "build", "web"))
	}
	for _, candidate := range candidates {
		if _, err := os.Stat(filepath.Join(candidate, "index.html")); err == nil {
			return candidate
		}
	}
	return ""
}

// resolveWebDir reports the web directory to serve, or "" when there is none.
// A path that does not hold an index.html is treated as absent rather than as
// an error: a server without a web app is a normal configuration.
func resolveWebDir(dir string) string {
	if dir == "" {
		return ""
	}
	if _, err := os.Stat(filepath.Join(dir, "index.html")); err != nil {
		return ""
	}
	return dir
}

// resolvePublicURL is the origin handed to clients in invite and attachment
// links. When it is not configured we guess from the listen address, which is
// right for local development and wrong behind a proxy — hence the flag.
// probeHealth asks the already-running server how it is doing and turns the
// answer into an exit code. It is the entry point a container health check uses:
// nothing else in the image can make an HTTP request.
func probeHealth(addr string) error {
	host, port, err := net.SplitHostPort(addr)
	if err != nil {
		return fmt.Errorf("invalid --addr %q: %w", addr, err)
	}
	// The server listens on every interface; 127.0.0.1 is the right probe target
	// for a wildcard bind (localhost can resolve to ::1, where nothing listens).
	if host == "" || host == "0.0.0.0" || host == "::" {
		host = "127.0.0.1"
	}
	client := &http.Client{Timeout: 3 * time.Second}
	resp, err := client.Get("http://" + net.JoinHostPort(host, port) + "/healthz")
	if err != nil {
		return fmt.Errorf("health probe: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("health probe: status %d", resp.StatusCode)
	}
	return nil
}

// runDeleteAccount removes an account and reports exactly what went with it.
//
// It opens the store directly — the store check refuses to start on a mismatch,
// which is the guard that keeps a delete from running against the wrong key —
// and it insists the server is stopped, because a second process writing the
// same SQLite file is the one thing this design does not support.
func runDeleteAccount(o options, username string, log *slog.Logger) error {
	st, err := store.Open(o.dataDir, log)
	if err != nil {
		return err
	}
	defer st.Close()

	if _, err := st.UserByUsername(username); err != nil {
		return fmt.Errorf("no account named %q in %s", username, o.dataDir)
	}
	summary, err := st.DeleteUserByUsername(username)
	if err != nil {
		return err
	}
	fmt.Printf("deleted account %q (%s)\n", summary.Username, summary.UserID)
	fmt.Printf("  sessions:                  %d\n", summary.Sessions)
	fmt.Printf("  push subscriptions:        %d\n", summary.PushSubscriptions)
	fmt.Printf("  device keys:               %d (with %d key envelopes)\n", summary.DeviceKeys, summary.KeyEnvelopes)
	fmt.Printf("  contacts:                  %d\n", summary.Contacts)
	fmt.Printf("  invitations:               %d\n", summary.Invites)
	fmt.Printf("  attachments:               %d (files removed)\n", summary.Attachments)
	fmt.Printf("  direct conversations:      %d (deleted, with %d messages)\n", summary.DirectChats, summary.Messages)
	fmt.Printf("  group memberships:         %d (messages kept)\n", summary.GroupMemberships)
	return nil
}

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
