package service

import "github.com/gokr/ratatosk/server/internal/store"

func (b *base) notifyMessage(m *store.Message) {
	if b.cfg.MessageNotifier != nil && m != nil && m.Kind == store.MessageText && !m.Deleted {
		b.cfg.MessageNotifier.Notify(m.ID, m.ConversationID, m.SenderID)
	}
}
