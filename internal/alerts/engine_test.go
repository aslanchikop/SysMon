package alerts

import (
	"bytes"
	"path/filepath"
	"testing"
	"time"

	"sysmon/internal/clock"
	"sysmon/internal/metrics"
)

const sampleConfigYAML = `
rules:
  - name: "High CPU Usage"
    metric: "cpu"
    operator: ">"
    threshold: 80.0
    duration: 5s
    message: "CPU usage exceeded 80%"

  - name: "High Memory Usage"
    metric: "memory"
    operator: ">="
    threshold: 90.0
    duration: 0s
    message: "Memory usage exceeded 90%"
`

func TestLoadConfig(t *testing.T) {
	buf := bytes.NewBufferString(sampleConfigYAML)
	cfg, err := LoadConfig(buf)
	if err != nil {
		t.Fatalf("failed to load config: %v", err)
	}

	if len(cfg.Rules) != 2 {
		t.Fatalf("expected 2 rules, got %d", len(cfg.Rules))
	}

	if cfg.Rules[0].Name != "High CPU Usage" || cfg.Rules[0].Threshold != 80.0 || cfg.Rules[0].Duration != 5*time.Second {
		t.Fatalf("unexpected rule 0: %+v", cfg.Rules[0])
	}
}

func TestEngineAlertEvaluation(t *testing.T) {
	tmpDir := t.TempDir()
	logPath := filepath.Join(tmpDir, "test_alerts.log")

	cfg, err := LoadConfig(bytes.NewBufferString(sampleConfigYAML))
	if err != nil {
		t.Fatalf("failed to parse yaml: %v", err)
	}

	start := time.Date(2025, 1, 1, 12, 0, 0, 0, time.UTC)
	mockClk := clock.NewMockClock(start)

	engine, err := NewEngine(cfg, mockClk, logPath)
	if err != nil {
		t.Fatalf("failed to create engine: %v", err)
	}
	defer engine.Close()

	// Snapshot 1: CPU = 85% (crosses 80% threshold, but duration is 5s), Memory = 50%
	snap1 := metrics.SystemSnapshot{
		Timestamp: mockClk.Now(),
		CPU:       metrics.CPUStats{TotalPercent: 85.0},
		Memory:    metrics.MemoryStats{RAMPercent: 50.0},
	}

	active := engine.Evaluate(snap1)
	if len(active) != 0 {
		t.Fatalf("expected 0 active alerts initially because CPU duration 5s not reached, got %d", len(active))
	}

	// Advance clock by 3s (total 3s < 5s)
	mockClk.Advance(3 * time.Second)
	snap2 := metrics.SystemSnapshot{
		Timestamp: mockClk.Now(),
		CPU:       metrics.CPUStats{TotalPercent: 85.0},
		Memory:    metrics.MemoryStats{RAMPercent: 50.0},
	}

	active = engine.Evaluate(snap2)
	if len(active) != 0 {
		t.Fatalf("expected 0 active alerts at 3s, got %d", len(active))
	}

	// Advance clock by 3s more (total 6s >= 5s)
	mockClk.Advance(3 * time.Second)
	snap3 := metrics.SystemSnapshot{
		Timestamp: mockClk.Now(),
		CPU:       metrics.CPUStats{TotalPercent: 85.0},
		Memory:    metrics.MemoryStats{RAMPercent: 50.0},
	}

	active = engine.Evaluate(snap3)
	if len(active) != 1 {
		t.Fatalf("expected 1 active alert at 6s, got %d", len(active))
	}
	if active[0].RuleName != "High CPU Usage" {
		t.Fatalf("expected 'High CPU Usage', got %s", active[0].RuleName)
	}

	// Now Memory spike to 95% (duration 0s -> should trigger immediately)
	snap4 := metrics.SystemSnapshot{
		Timestamp: mockClk.Now(),
		CPU:       metrics.CPUStats{TotalPercent: 85.0},
		Memory:    metrics.MemoryStats{RAMPercent: 95.0},
	}
	active = engine.Evaluate(snap4)
	if len(active) != 2 {
		t.Fatalf("expected 2 active alerts, got %d", len(active))
	}

	// CPU drops back to 70% -> Should resolve CPU alert
	mockClk.Advance(1 * time.Second)
	snap5 := metrics.SystemSnapshot{
		Timestamp: mockClk.Now(),
		CPU:       metrics.CPUStats{TotalPercent: 70.0},
		Memory:    metrics.MemoryStats{RAMPercent: 95.0},
	}
	active = engine.Evaluate(snap5)
	if len(active) != 1 || active[0].RuleName != "High Memory Usage" {
		t.Fatalf("expected only High Memory Usage alert remaining, got %+v", active)
	}

	if engine.IsRuleActive("High CPU Usage") {
		t.Fatalf("High CPU Usage should no longer be active")
	}

	// Check event log
	events := engine.EventLog()
	if len(events) < 3 { // Trigger CPU, Trigger Mem, Resolve CPU
		t.Fatalf("expected at least 3 log events, got %d", len(events))
	}
}
