package metrics

import (
	"fmt"
	"sync"
	"time"

	"github.com/shirou/gopsutil/v3/cpu"
	"github.com/shirou/gopsutil/v3/disk"
	"github.com/shirou/gopsutil/v3/mem"
	"github.com/shirou/gopsutil/v3/net"
	"sysmon/internal/clock"
)

// HistoryBuffer keeps a fixed size rolling slice of float64 data points (e.g. 60 seconds).
type HistoryBuffer struct {
	capacity int
	data     []float64
	mu       sync.RWMutex
}

func NewHistoryBuffer(capacity int) *HistoryBuffer {
	if capacity <= 0 {
		capacity = 60
	}
	return &HistoryBuffer{
		capacity: capacity,
		data:     make([]float64, 0, capacity),
	}
}

func (h *HistoryBuffer) Add(val float64) {
	h.mu.Lock()
	defer h.mu.Unlock()

	if len(h.data) >= h.capacity {
		h.data = append(h.data[1:], val)
	} else {
		h.data = append(h.data, val)
	}
}

func (h *HistoryBuffer) Data() []float64 {
	h.mu.RLock()
	defer h.mu.RUnlock()

	res := make([]float64, len(h.data))
	copy(res, h.data)
	return res
}

func (h *HistoryBuffer) Latest() float64 {
	h.mu.RLock()
	defer h.mu.RUnlock()

	if len(h.data) == 0 {
		return 0
	}
	return h.data[len(h.data)-1]
}

// CPUStats holds total CPU percentage and per-core percentages.
type CPUStats struct {
	TotalPercent float64
	CoresPercent []float64
}

// MemoryStats holds RAM and Swap details.
type MemoryStats struct {
	TotalRAM     uint64
	UsedRAM      uint64
	FreeRAM      uint64
	RAMPercent   float64
	TotalSwap    uint64
	UsedSwap     uint64
	FreeSwap     uint64
	SwapPercent  float64
}

// DiskPartitionStats holds info for a single disk partition.
type DiskPartitionStats struct {
	Device      string
	Mountpoint  string
	Fstype      string
	Total       uint64
	Used        uint64
	Free        uint64
	UsedPercent float64
}

// NetworkInterfaceStats holds network statistics and calculated speed (bytes/sec).
type NetworkInterfaceStats struct {
	Name        string
	BytesSent   uint64
	BytesRecv   uint64
	TxSpeedBps float64 // bytes per second
	RxSpeedBps float64 // bytes per second
}

// SystemSnapshot represents a single point-in-time metrics sample.
type SystemSnapshot struct {
	Timestamp time.Time
	CPU       CPUStats
	Memory    MemoryStats
	Disks     []DiskPartitionStats
	Networks  []NetworkInterfaceStats
}

// MetricsProvider defines an interface for fetching metrics (easy to mock in tests).
type MetricsProvider interface {
	GetCPUPercent() (float64, []float64, error)
	GetMemoryInfo() (MemoryStats, error)
	GetDiskInfo() ([]DiskPartitionStats, error)
	GetNetworkInfo() ([]net.IOCountersStat, error)
}

// GopsutilProvider implements MetricsProvider using gopsutil.
type GopsutilProvider struct{}

func (g *GopsutilProvider) GetCPUPercent() (float64, []float64, error) {
	total, err := cpu.Percent(0, false)
	if err != nil {
		return 0, nil, fmt.Errorf("failed to get total cpu percent: %w", err)
	}
	cores, err := cpu.Percent(0, true)
	if err != nil {
		return 0, nil, fmt.Errorf("failed to get cores cpu percent: %w", err)
	}
	totalVal := 0.0
	if len(total) > 0 {
		totalVal = total[0]
	}
	return totalVal, cores, nil
}

func (g *GopsutilProvider) GetMemoryInfo() (MemoryStats, error) {
	vm, err := mem.VirtualMemory()
	if err != nil {
		return MemoryStats{}, fmt.Errorf("failed to get virtual memory: %w", err)
	}
	sw, err := mem.SwapMemory()
	if err != nil {
		return MemoryStats{}, fmt.Errorf("failed to get swap memory: %w", err)
	}

	return MemoryStats{
		TotalRAM:    vm.Total,
		UsedRAM:     vm.Used,
		FreeRAM:     vm.Free,
		RAMPercent:  vm.UsedPercent,
		TotalSwap:   sw.Total,
		UsedSwap:    sw.Used,
		FreeSwap:    sw.Free,
		SwapPercent: sw.UsedPercent,
	}, nil
}

func (g *GopsutilProvider) GetDiskInfo() ([]DiskPartitionStats, error) {
	partitions, err := disk.Partitions(false)
	if err != nil {
		return nil, fmt.Errorf("failed to get partitions: %w", err)
	}

	var res []DiskPartitionStats
	seen := make(map[string]bool)

	for _, p := range partitions {
		if seen[p.Mountpoint] {
			continue
		}
		seen[p.Mountpoint] = true

		usage, err := disk.Usage(p.Mountpoint)
		if err != nil {
			continue
		}
		res = append(res, DiskPartitionStats{
			Device:      p.Device,
			Mountpoint:  p.Mountpoint,
			Fstype:      p.Fstype,
			Total:       usage.Total,
			Used:        usage.Used,
			Free:        usage.Free,
			UsedPercent: usage.UsedPercent,
		})
	}
	return res, nil
}

func (g *GopsutilProvider) GetNetworkInfo() ([]net.IOCountersStat, error) {
	counters, err := net.IOCounters(true)
	if err != nil {
		return nil, fmt.Errorf("failed to get net io counters: %w", err)
	}
	return counters, nil
}

// Collector orchestrates metrics collection and history retention.
type Collector struct {
	provider    MetricsProvider
	clk         clock.Clock
	historyLen  int

	mu          sync.RWMutex
	latest      SystemSnapshot
	prevNet     map[string]net.IOCountersStat
	prevNetTime time.Time

	// History buffers
	CPUHistory   *HistoryBuffer
	RAMHistory   *HistoryBuffer
	SwapHistory  *HistoryBuffer
	NetRxHistory map[string]*HistoryBuffer
	NetTxHistory map[string]*HistoryBuffer
}

func NewCollector(provider MetricsProvider, clk clock.Clock, historyLen int) *Collector {
	if historyLen <= 0 {
		historyLen = 60
	}
	if provider == nil {
		provider = &GopsutilProvider{}
	}
	if clk == nil {
		clk = clock.NewRealClock()
	}

	return &Collector{
		provider:     provider,
		clk:          clk,
		historyLen:   historyLen,
		prevNet:      make(map[string]net.IOCountersStat),
		CPUHistory:   NewHistoryBuffer(historyLen),
		RAMHistory:   NewHistoryBuffer(historyLen),
		SwapHistory:  NewHistoryBuffer(historyLen),
		NetRxHistory: make(map[string]*HistoryBuffer),
		NetTxHistory: make(map[string]*HistoryBuffer),
	}
}

func (c *Collector) Collect() (SystemSnapshot, error) {
	c.mu.Lock()
	defer c.mu.Unlock()

	now := c.clk.Now()
	totalCPU, coresCPU, err := c.provider.GetCPUPercent()
	if err != nil {
		// Log or handle, use 0 on fallback
		totalCPU = 0
	}

	memStats, _ := c.provider.GetMemoryInfo()
	disks, _ := c.provider.GetDiskInfo()
	netCounters, _ := c.provider.GetNetworkInfo()

	// Calculate net speeds
	var netStats []NetworkInterfaceStats
	var timeDiff float64
	if !c.prevNetTime.IsZero() {
		timeDiff = now.Sub(c.prevNetTime).Seconds()
	}

	for _, nc := range netCounters {
		stat := NetworkInterfaceStats{
			Name:      nc.Name,
			BytesSent: nc.BytesSent,
			BytesRecv: nc.BytesRecv,
		}

		if prev, ok := c.prevNet[nc.Name]; ok && timeDiff > 0 {
			if nc.BytesRecv >= prev.BytesRecv {
				stat.RxSpeedBps = float64(nc.BytesRecv-prev.BytesRecv) / timeDiff
			}
			if nc.BytesSent >= prev.BytesSent {
				stat.TxSpeedBps = float64(nc.BytesSent-prev.BytesSent) / timeDiff
			}
		}

		c.prevNet[nc.Name] = nc
		netStats = append(netStats, stat)

		// Update net history buffers
		if _, ok := c.NetRxHistory[nc.Name]; !ok {
			c.NetRxHistory[nc.Name] = NewHistoryBuffer(c.historyLen)
		}
		if _, ok := c.NetTxHistory[nc.Name]; !ok {
			c.NetTxHistory[nc.Name] = NewHistoryBuffer(c.historyLen)
		}
		c.NetRxHistory[nc.Name].Add(stat.RxSpeedBps)
		c.NetTxHistory[nc.Name].Add(stat.TxSpeedBps)
	}

	c.prevNetTime = now

	// Update global histories
	c.CPUHistory.Add(totalCPU)
	c.RAMHistory.Add(memStats.RAMPercent)
	c.SwapHistory.Add(memStats.SwapPercent)

	snap := SystemSnapshot{
		Timestamp: now,
		CPU: CPUStats{
			TotalPercent: totalCPU,
			CoresPercent: coresCPU,
		},
		Memory:   memStats,
		Disks:    disks,
		Networks: netStats,
	}

	c.latest = snap
	return snap, nil
}

func (c *Collector) LatestSnapshot() SystemSnapshot {
	c.mu.RLock()
	defer c.mu.RUnlock()
	return c.latest
}
