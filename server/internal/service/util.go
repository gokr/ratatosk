package service

import (
	"strings"
)

// trimSpace is the one place the service layer trims user input, so the rules
// are identical everywhere.
func trimSpace(s string) string { return strings.TrimSpace(s) }

// validHexColor accepts "#rgb" and "#rrggbb".
func validHexColor(s string) bool {
	if !strings.HasPrefix(s, "#") {
		return false
	}
	body := s[1:]
	if len(body) != 3 && len(body) != 6 {
		return false
	}
	for _, r := range body {
		switch {
		case r >= '0' && r <= '9', r >= 'a' && r <= 'f', r >= 'A' && r <= 'F':
		default:
			return false
		}
	}
	return true
}

// normalPath joins an origin and a path without doubling slashes.
func normalPath(origin, path string) string {
	if origin == "" {
		return path
	}
	return strings.TrimRight(origin, "/") + path
}
