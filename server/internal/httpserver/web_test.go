package httpserver_test

import (
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gokr/ratatosk/server/internal/httpserver"
	"github.com/gokr/ratatosk/server/internal/realtime"
	"github.com/gokr/ratatosk/server/internal/service"
	"github.com/gokr/ratatosk/server/internal/store"
	"log/slog"
)

// TestServerServesTheWebApp covers the one-origin deployment: the app at /, the
// API on its own paths, and the invitation landing page still winning over the
// app's fallback.
func TestServerServesTheWebApp(t *testing.T) {
	dir := t.TempDir()
	webDir := filepath.Join(dir, "web")
	if err := os.MkdirAll(filepath.Join(webDir, "assets"), 0o755); err != nil {
		t.Fatalf("mkdir: %v", err)
	}
	write := func(name, body string) {
		if err := os.WriteFile(filepath.Join(webDir, name), []byte(body), 0o644); err != nil {
			t.Fatalf("write %s: %v", name, err)
		}
	}
	write("index.html", "<!DOCTYPE html><title>Ratatosk app</title>")
	write("flutter_bootstrap.js", "// bootstrap")
	write(filepath.Join("assets", "main.dart.js"), "// the app")

	log := slog.New(slog.NewTextHandler(io.Discard, nil))
	st, err := store.Open(filepath.Join(dir, "data"), log)
	if err != nil {
		t.Fatalf("open store: %v", err)
	}
	defer st.Close()
	hub := realtime.NewHub()
	presence := realtime.NewTracker(st, hub, nil, 0, log)
	services := service.New(st, hub, presence, service.DefaultConfig(), log)
	handler := httpserver.New(httpserver.Config{
		PublicURL: "http://example.test",
		WebDir:    webDir,
		Log:       log,
	}, st, hub, presence, services)
	srv := newTestServer(t, handler)

	get := func(path string) (int, string, http.Header) {
		res, err := srv.Client().Get(srv.URL + path)
		if err != nil {
			t.Fatalf("GET %s: %v", path, err)
		}
		defer res.Body.Close()
		body, _ := io.ReadAll(res.Body)
		return res.StatusCode, string(body), res.Header
	}

	// The app is at /.
	status, body, _ := get("/")
	if status != 200 || !strings.Contains(body, "Ratatosk app") {
		t.Fatalf("GET / = %d %q", status, body)
	}

	// Its assets are served. They must be revalidated, not cached on trust:
	// Flutter's entry points are not content-addressed, so a long max-age would
	// keep serving the previous build after a redeploy.
	status, body, header := get("/flutter_bootstrap.js")
	if status != 200 || body != "// bootstrap" {
		t.Fatalf("bootstrap = %d %q", status, body)
	}
	if cache := header.Get("Cache-Control"); !strings.Contains(cache, "no-cache") {
		t.Errorf("asset Cache-Control = %q, want no-cache so a redeploy is picked up", cache)
	}
	status, _, _ = get("/assets/main.dart.js")
	if status != 200 {
		t.Fatalf("asset status = %d", status)
	}

	// An unchanged file still costs only a 304, so revalidation is cheap.
	_, _, header = get("/")
	if cache := header.Get("Cache-Control"); !strings.Contains(cache, "no-cache") {
		t.Errorf("index Cache-Control = %q, want no-cache", cache)
	}
	res, err := srv.Client().Get(srv.URL + "/")
	if err != nil {
		t.Fatalf("GET /: %v", err)
	}
	etag := res.Header.Get("Last-Modified")
	res.Body.Close()
	req, _ := http.NewRequest(http.MethodGet, srv.URL+"/", nil)
	req.Header.Set("If-Modified-Since", etag)
	revalidated, err := srv.Client().Do(req)
	if err != nil {
		t.Fatalf("revalidate: %v", err)
	}
	defer revalidated.Body.Close()
	if revalidated.StatusCode != http.StatusNotModified {
		t.Errorf("revalidation status = %d, want 304", revalidated.StatusCode)
	}

	// A URL the app itself handles (an invitation in a query string) falls back
	// to the app rather than 404ing.
	status, body, _ = get("/?invite=abc123")
	if status != 200 || !strings.Contains(body, "Ratatosk app") {
		t.Fatalf("app fallback = %d %q", status, body)
	}
	status, body, _ = get("/some/client/route")
	if status != 200 || !strings.Contains(body, "Ratatosk app") {
		t.Fatalf("client route fallback = %d %q", status, body)
	}

	// The API is not shadowed by the app or by the fallback.
	status, body, _ = get("/healthz")
	if status != 200 || !strings.Contains(body, `"status": "ok"`) {
		t.Fatalf("healthz = %d %q", status, body)
	}
	// An RPC path answered by the app would be a silent, confusing failure.
	status, _, _ = get("/ratatosk.v1.ChatService/ListConversations")
	if status == 200 {
		t.Fatalf("an RPC path was answered by the web app (status %d)", status)
	}

	// The invitation landing page stays server-rendered: it has to name the
	// inviter before anyone has the app or an account.
	status, body, _ = get("/join/does-not-exist")
	if status != 200 || !strings.Contains(body, "Invitation not available") {
		t.Fatalf("invite page = %d %q", status, body)
	}
	// A traversal attempt must never serve a file from outside the web
	// directory. Go's client normalizes a plain "../" away before it is sent, so
	// the encoded form is used, which reaches the handler intact: the request
	// then falls back to the app, and crucially does not leak a system file.
	for _, path := range []string{"/%2e%2e%2f%2e%2e%2fetc%2fpasswd", "/../../etc/passwd"} {
		status, body, _ := get(path)
		if strings.Contains(body, "root:") {
			t.Fatalf("GET %s leaked a system file", path)
		}
		if status == 200 && !strings.Contains(body, "Ratatosk app") {
			t.Fatalf("GET %s = %d %q, want the app or a 404", path, status, body)
		}
	}
}

// A server with no web directory must still answer the API and say what it is.
func TestServerWithoutAWebApp(t *testing.T) {
	dir := t.TempDir()
	log := slog.New(slog.NewTextHandler(io.Discard, nil))
	st, err := store.Open(dir, log)
	if err != nil {
		t.Fatalf("open store: %v", err)
	}
	defer st.Close()
	hub := realtime.NewHub()
	presence := realtime.NewTracker(st, hub, nil, 0, log)
	services := service.New(st, hub, presence, service.DefaultConfig(), log)
	handler := httpserver.New(httpserver.Config{PublicURL: "http://example.test", Log: log}, st, hub, presence, services)
	srv := newTestServer(t, handler)

	res, err := srv.Client().Get(srv.URL + "/")
	if err != nil {
		t.Fatalf("GET /: %v", err)
	}
	defer res.Body.Close()
	body, _ := io.ReadAll(res.Body)
	if res.StatusCode != 200 || !strings.Contains(string(body), `"ratatosk"`) {
		t.Fatalf("GET / = %d %q", res.StatusCode, string(body))
	}
	if !strings.Contains(string(body), "flutter build web") {
		t.Error("the API description should say how to build the web app")
	}

	// An unknown path with no app to fall back to is still a 404.
	res, err = srv.Client().Get(srv.URL + "/nope")
	if err != nil {
		t.Fatalf("GET /nope: %v", err)
	}
	res.Body.Close()
	if res.StatusCode != 404 {
		t.Fatalf("unknown path = %d, want 404", res.StatusCode)
	}
}

// A request that is not a GET must never be answered with the app: an RPC whose
// url went astray should fail clearly rather than receive HTML.
func TestWebAppDoesNotAnswerNonGetRequests(t *testing.T) {
	dir := t.TempDir()
	webDir := filepath.Join(dir, "web")
	if err := os.MkdirAll(webDir, 0o755); err != nil {
		t.Fatalf("mkdir: %v", err)
	}
	if err := os.WriteFile(filepath.Join(webDir, "index.html"), []byte("<!DOCTYPE html><title>app</title>"), 0o644); err != nil {
		t.Fatalf("write: %v", err)
	}

	log := slog.New(slog.NewTextHandler(io.Discard, nil))
	st, err := store.Open(filepath.Join(dir, "data"), log)
	if err != nil {
		t.Fatalf("open store: %v", err)
	}
	defer st.Close()
	hub := realtime.NewHub()
	presence := realtime.NewTracker(st, hub, nil, 0, log)
	services := service.New(st, hub, presence, service.DefaultConfig(), log)
	handler := httpserver.New(httpserver.Config{PublicURL: "http://example.test", WebDir: webDir, Log: log}, st, hub, presence, services)
	srv := newTestServer(t, handler)

	// This is the request shape a client with a broken base url produces: the
	// procedure ends up after the query string, so the path it hits is just "/".
	res, err := srv.Client().Post(srv.URL+"/", "application/json", strings.NewReader("{}"))
	if err != nil {
		t.Fatalf("POST /: %v", err)
	}
	defer res.Body.Close()
	body, _ := io.ReadAll(res.Body)
	if res.StatusCode != 404 {
		t.Fatalf("POST / = %d, want 404 (body %q)", res.StatusCode, string(body))
	}
	if strings.Contains(string(body), "<title>") {
		t.Fatal("a non-GET request was answered with the web app")
	}
}
