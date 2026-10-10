// Package ids generates the opaque identifiers used across the store.
//
// Identifiers are random, not sequential: they appear in URLs (attachments,
// invite landing pages) and in the wire protocol, so they must not leak
// counts, ordering or creation time.
package ids

import (
	"crypto/rand"
	"encoding/hex"
)

// codeAlphabet omits characters that are easy to confuse when someone reads an
// invite code aloud or retypes it: 0/O, 1/l/I, 2/Z, 5/S, 8/B.
const codeAlphabet = "346789abcdefghjkmnpqrstuvwxyz"

// New returns a prefixed random identifier, e.g. New("u") -> "u3f9a2c1b8d4e5f60".
//
// The prefix is a debugging aid and a cheap guard against mixing kinds up; it
// is always a single character so ids have a fixed length.
func New(prefix string) string {
	var b [8]byte
	if _, err := rand.Read(b[:]); err != nil {
		// crypto/rand only fails if the kernel CSPRNG is unavailable, in which
		// case every part of the server is unsafe. Fail loudly rather than
		// silently handing out predictable identifiers.
		panic("ids: crypto/rand unavailable: " + err.Error())
	}
	return prefix + hex.EncodeToString(b[:])
}

// Code returns a random invite code of n characters drawn from an unambiguous
// alphabet, readable over the phone and typo-resistant.
func Code(n int) string {
	out := make([]byte, n)
	// Rejection sampling keeps the distribution uniform over the alphabet.
	buf := make([]byte, n*2)
	for i := 0; i < n; {
		if _, err := rand.Read(buf); err != nil {
			panic("ids: crypto/rand unavailable: " + err.Error())
		}
		for _, v := range buf {
			// Largest multiple of len(codeAlphabet) that fits in a byte; values
			// at or above it would bias the modulo.
			if int(v) >= 256-256%len(codeAlphabet) {
				continue
			}
			out[i] = codeAlphabet[int(v)%len(codeAlphabet)]
			i++
			if i == n {
				break
			}
		}
	}
	return string(out)
}

// Token returns a hex session token with 256 bits of entropy.
func Token() string {
	var b [32]byte
	if _, err := rand.Read(b[:]); err != nil {
		panic("ids: crypto/rand unavailable: " + err.Error())
	}
	return hex.EncodeToString(b[:])
}
