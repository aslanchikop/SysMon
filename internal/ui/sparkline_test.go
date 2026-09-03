package ui

import (
	"testing"
)

func TestRenderSparkline(t *testing.T) {
	data := []float64{0, 25, 50, 75, 100}
	res := RenderSparkline(data, 0, 100, 5)
	if len([]rune(res)) != 5 {
		t.Fatalf("expected length 5, got %d", len([]rune(res)))
	}

	// First rune should be lowest block, last rune highest block
	runes := []rune(res)
	if runes[0] != ' ' {
		t.Fatalf("expected space for 0, got %c", runes[0])
	}
	if runes[4] != '█' {
		t.Fatalf("expected full block for 100, got %c", runes[4])
	}
}

func TestFormatBytes(t *testing.T) {
	if FormatBytes(500) != "500 B" {
		t.Fatalf("got %s", FormatBytes(500))
	}
	if FormatBytes(1024) != "1.0 KB" {
		t.Fatalf("got %s", FormatBytes(1024))
	}
	if FormatBytes(1048576) != "1.0 MB" {
		t.Fatalf("got %s", FormatBytes(1048576))
	}
}

func TestFormatSpeed(t *testing.T) {
	if FormatSpeed(500) != "500 B/s" {
		t.Fatalf("got %s", FormatSpeed(500))
	}
	if FormatSpeed(1500) != "1.5 KB/s" {
		t.Fatalf("got %s", FormatSpeed(1500))
	}
}
