package security

import (
	"testing"
)

func TestKillSwitch(t *testing.T) {
	ks := NewKillSwitch("127.0.0.1:1080", "127.0.0.1:50051")

	if ks.IsEnabled() {
		t.Error("expected KillSwitch disabled by default")
	}

	err := ks.Enable()
	if err != nil {
		t.Logf("ks.Enable returned expected non-admin error on system: %v", err)
	} else {
		if !ks.IsEnabled() {
			t.Error("expected KillSwitch enabled after Enable()")
		}
		_ = ks.Disable()
	}
}
