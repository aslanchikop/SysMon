package clock

import (
	"testing"
	"time"
)

func TestMockClock(t *testing.T) {
	start := time.Date(2025, 1, 1, 0, 0, 0, 0, time.UTC)
	mc := NewMockClock(start)

	if !mc.Now().Equal(start) {
		t.Fatalf("expected start time %v, got %v", start, mc.Now())
	}

	mc.Advance(10 * time.Second)
	expected := start.Add(10 * time.Second)
	if !mc.Now().Equal(expected) {
		t.Fatalf("expected time after advance %v, got %v", expected, mc.Now())
	}

	select {
	case chTime := <-mc.After(5 * time.Second):
		if !chTime.Equal(expected.Add(5 * time.Second)) {
			t.Fatalf("expected channel time %v, got %v", expected.Add(5*time.Second), chTime)
		}
	default:
		t.Fatal("expected message on channel")
	}
}
