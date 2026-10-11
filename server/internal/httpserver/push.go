package httpserver

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/gokr/ratatosk/server/internal/push"
	"github.com/gokr/ratatosk/server/internal/store"
)

func (s *Server) servePushConfig(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Cache-Control", "no-store")
	writeJSON(w, http.StatusOK, map[string]any{"enabled": s.cfg.Push.Enabled(), "publicKey": s.cfg.Push.PublicKey()})
}

func (s *Server) servePushSubscription(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Cache-Control", "no-store")
	raw := r.Header.Get("Authorization")
	if len(raw) < 8 || !strings.EqualFold(raw[:7], "Bearer ") {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	token := strings.TrimSpace(raw[7:])
	session, err := s.st.SessionByToken(token, time.Now())
	if err != nil {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	if !s.cfg.Push.Enabled() {
		http.Error(w, "push disabled", http.StatusServiceUnavailable)
		return
	}
	var body struct {
		Endpoint string `json:"endpoint"`
		Keys     struct {
			P256DH string `json:"p256dh"`
			Auth   string `json:"auth"`
		} `json:"keys"`
	}
	dec := json.NewDecoder(http.MaxBytesReader(w, r.Body, 8192))
	dec.DisallowUnknownFields()
	if err := dec.Decode(&body); err != nil {
		http.Error(w, "invalid subscription", http.StatusBadRequest)
		return
	}
	if err := dec.Decode(new(any)); err != io.EOF {
		http.Error(w, "invalid subscription", http.StatusBadRequest)
		return
	}
	if body.Endpoint == "" || len(body.Endpoint) > 4096 {
		http.Error(w, "invalid endpoint", http.StatusBadRequest)
		return
	}
	if r.Method == http.MethodDelete {
		err = s.st.DeletePushSubscription(body.Endpoint, session.UserID, token)
	} else {
		if err := push.ValidateKeys(body.Keys.P256DH, body.Keys.Auth); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		if err := push.ValidateEndpoint(r.Context(), body.Endpoint); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		err = s.st.PutPushSubscription(&store.PushSubscription{Endpoint: body.Endpoint, UserID: session.UserID, SessionToken: token, P256DH: body.Keys.P256DH, Auth: body.Keys.Auth, CreatedAt: time.Now()})
	}
	if err != nil {
		if errors.Is(err, store.ErrAlreadyExists) {
			http.Error(w, "subscription belongs to another session", http.StatusConflict)
			return
		}
		if errors.Is(err, store.ErrNotFound) {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		http.Error(w, "subscription update failed", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
