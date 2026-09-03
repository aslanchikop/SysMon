package metrics

import (
	"testing"
	"time"

	"github.com/shirou/gopsutil/v3/net"
	"sysmon/internal/clock"
)

type MockProvider struct {
	CPUTotal float64
	CPUCores []float64
	Mem      MemoryStats
	Disks    []DiskPartitionStats
	Net      []net.IOCountersStat
}

func (m *MockProvider) GetCPUPercent() (float64, []float64, error) {
	return m.CPUTotal, m.CPUCores, nil
}

func (m *MockProvider) GetMemoryInfo() (MemoryStats, error) {
	return m.Mem, nil
}

func (m *MockProvider) GetDiskInfo() ([]DiskPartitionStats, error) {
	return m.Disks, nil
}

func (m *MockProvider) GetNetworkInfo() ([]net.IOCountersStat, error) {
	return m.Net, nil
}

func TestHistoryBuffer(t *testing.T) {
	hb := NewHistoryBuffer(3)
	if len(hb.Data()) != 0 {
		t.Fatalf("expected empty buffer")
	}

	hb.Add(10)
	hb.Add(20)
	hb.Add(30)
	data := hb.Data()
	if len(data) != 3 || data[0] != 10 || data[2] != 30 {
		t.Fatalf("unexpected data: %v", data)
	}

	hb.Add(40) // Should drop 10
	data = hb.Data()
	if len(data) != 3 || data[0] != 20 || data[2] != 40 {
		t.Fatalf("unexpected data after overflow: %v", data)
	}
	if hb.Latest() != 40 {
		t.Fatalf("expected latest 40, got %f", hb.Latest())
	}
}

func TestCollector(t *testing.T) {
	mockClk := clock.NewMockClock(time.Date(2025, 1, 1, 12, 0, 0, 0, time.UTC))
	mockProv := &MockProvider{
		CPUTotal: 45.5,
		CPUCores: []float64{40.0, 51.0},
		Mem: MemoryStats{
			TotalRAM:   16000000000,
			UsedRAM:    8000000000,
			RAMPercent: 50.0,
		},
		Disks: []DiskPartitionStats{
			{Device: "/dev/sda1", Mountpoint: "/", UsedPercent: 60.0},
		},
		Net: []net.IOCountersStat{
			{Name: "eth0", BytesRecv: 1000, BytesSent: 500},
		},
	}

	col := NewCollector(mockProv, mockClk, 60)

	// Sample 1
	snap1, err := col.Collect()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if snap1.CPU.TotalPercent != 45.5 {
		t.Fatalf("expected CPU total 45.5, got %f", snap1.CPU.TotalPercent)
	}
	if snap1.Memory.RAMPercent != 50.0 {
		t.Fatalf("expected RAM percent 50.0, got %f", snap1.Memory.RAMPercent)
	}
	if len(snap1.Networks) != 1 || snap1.Networks[0].RxSpeedBps != 0 {
		t.Fatalf("expected initial network speed 0")
	}

	// Advance time by 2 seconds and increase network counters
	mockClk.Advance(2 * time.Second)
	mockProv.Net = []net.IOCountersStat{
		{Name: "eth0", BytesRecv: 3000, BytesSent: 1500}, // +2000 rx (+1000/s), +1000 tx (+500/s)
	}

	// Sample 2
	snap2, err := col.Collect()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(snap2.Networks) != 1 {
		t.Fatalf("expected 1 network interface")
	}

	rxSpeed := snap2.Networks[0].RxSpeedBps
	txSpeed := snap2.Networks[0].TxSpeedBps

	if rxSpeed != 1000.0 {
		t.Fatalf("expected Rx speed 1000 B/s, got %f", rxSpeed)
	}
	if txSpeed != 500.0 {
		t.Fatalf("expected Tx speed 500 B/s, got %f", txSpeed)
	}

	if len(col.CPUHistory.Data()) != 2 {
		t.Fatalf("expected 2 CPU history samples, got %d", len(col.CPUHistory.Data()))
	}
}
