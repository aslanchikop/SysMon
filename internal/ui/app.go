package ui

import (
	"fmt"
	"strings"
	"time"

	"github.com/gdamore/tcell/v2"
	"github.com/rivo/tview"
	"sysmon/internal/alerts"
	"sysmon/internal/clock"
	"sysmon/internal/metrics"
)

type App struct {
	tviewApp  *tview.Application
	collector *metrics.Collector
	engine    *alerts.Engine
	clk       clock.Clock

	pages      *tview.Pages
	tabButtons *tview.TextView
	activeTab  int
	tabNames   []string

	// UI Views
	summaryView *tview.TextView
	cpuView     *tview.TextView
	memDiskView *tview.TextView
	netView     *tview.TextView
	alertsView  *tview.TextView

	ticker *time.Ticker
	stopCh chan struct{}
}

func NewApp(collector *metrics.Collector, engine *alerts.Engine, clk clock.Clock) *App {
	if clk == nil {
		clk = clock.NewRealClock()
	}

	app := &App{
		tviewApp:  tview.NewApplication(),
		collector: collector,
		engine:    engine,
		clk:       clk,
		tabNames:  []string{"[1] CPU", "[2] RAM / Swap / Disks", "[3] Network", "[4] Alerts & Logs"},
		stopCh:    make(chan struct{}),
	}

	app.initUI()
	return app
}

func (a *App) initUI() {
	a.tabButtons = tview.NewTextView().
		SetDynamicColors(true).
		SetRegions(true).
		SetWrap(false)

	a.pages = tview.NewPages()

	// 1. CPU View
	a.cpuView = tview.NewTextView().
		SetDynamicColors(true).
		SetScrollable(true).
		SetWrap(true)
	a.cpuView.SetBorder(true).SetTitle(" CPU Metrics (60s sparkline) ")

	// 2. Memory & Disk View
	a.memDiskView = tview.NewTextView().
		SetDynamicColors(true).
		SetScrollable(true).
		SetWrap(true)
	a.memDiskView.SetBorder(true).SetTitle(" Memory, Swap & Storage ")

	// 3. Network View
	a.netView = tview.NewTextView().
		SetDynamicColors(true).
		SetScrollable(true).
		SetWrap(true)
	a.netView.SetBorder(true).SetTitle(" Network Interfaces ")

	// 4. Alerts & Logs View
	a.alertsView = tview.NewTextView().
		SetDynamicColors(true).
		SetScrollable(true).
		SetWrap(true)
	a.alertsView.SetBorder(true).SetTitle(" Active Alerts & System Event Log ")

	// Add views to pages
	a.pages.AddPage("0", a.cpuView, true, true)
	a.pages.AddPage("1", a.memDiskView, true, false)
	a.pages.AddPage("2", a.netView, true, false)
	a.pages.AddPage("3", a.alertsView, true, false)

	// Summary bar at the top
	a.summaryView = tview.NewTextView().
		SetDynamicColors(true).
		SetWrap(false)

	// Main Layout
	layout := tview.NewFlex().
		SetDirection(tview.FlexRow).
		AddItem(a.summaryView, 1, 0, false).
		AddItem(a.tabButtons, 1, 0, false).
		AddItem(a.pages, 0, 1, true)

	a.tviewApp.SetRoot(layout, true)
	a.updateTabsHeader()

	// Keyboard shortcut navigation
	a.tviewApp.SetInputCapture(func(event *tcell.EventKey) *tcell.EventKey {
		if event.Key() == tcell.KeyTab {
			a.activeTab = (a.activeTab + 1) % len(a.tabNames)
			a.switchTab(a.activeTab)
			return nil
		}
		if event.Key() == tcell.KeyBacktab {
			a.activeTab = (a.activeTab - 1 + len(a.tabNames)) % len(a.tabNames)
			a.switchTab(a.activeTab)
			return nil
		}
		switch event.Rune() {
		case '1':
			a.switchTab(0)
			return nil
		case '2':
			a.switchTab(1)
			return nil
		case '3':
			a.switchTab(2)
			return nil
		case '4':
			a.switchTab(3)
			return nil
		case 'q', 'Q':
			a.Stop()
			return nil
		}
		return event
	})
}

func (a *App) switchTab(index int) {
	a.activeTab = index
	a.updateTabsHeader()
	a.pages.SwitchToPage(fmt.Sprintf("%d", index))
}

func (a *App) updateTabsHeader() {
	var tabs []string
	for i, name := range a.tabNames {
		if i == a.activeTab {
			tabs = append(tabs, fmt.Sprintf("[yellow:blue:b] %s [-:-:-]", name))
		} else {
			tabs = append(tabs, fmt.Sprintf("[white:darkgray] %s [-:-:-]", name))
		}
	}
	a.tabButtons.SetText(strings.Join(tabs, " "))
}

func (a *App) Run() error {
	a.ticker = time.NewTicker(1 * time.Second)

	// Initial metrics collect & update
	a.updateMetrics()

	// Start background refresh loop
	go func() {
		for {
			select {
			case <-a.ticker.C:
				a.updateMetrics()
			case <-a.stopCh:
				return
			}
		}
	}()

	return a.tviewApp.Run()
}

func (a *App) Stop() {
	if a.ticker != nil {
		a.ticker.Stop()
	}
	close(a.stopCh)
	a.tviewApp.Stop()
}

func (a *App) updateMetrics() {
	snap, err := a.collector.Collect()
	if err != nil {
		return
	}

	activeAlerts := a.engine.Evaluate(snap)

	a.tviewApp.QueueUpdateDraw(func() {
		a.renderSummaryBar(snap, activeAlerts)
		a.renderCPUView(snap)
		a.renderMemDiskView(snap)
		a.renderNetView(snap)
		a.renderAlertsView(activeAlerts)
	})
}

func (a *App) renderSummaryBar(snap metrics.SystemSnapshot, active []alerts.ActiveAlert) {
	alertStatus := "[green]● Systems Normal[-]"
	if len(active) > 0 {
		alertStatus = fmt.Sprintf("[red:blink]⚠ %d ALERTS ACTIVE![-:-]", len(active))
	}

	summary := fmt.Sprintf(" SysMon | Time: %s | CPU: %.1f%% | RAM: %.1f%% | %s | [yellow]Tab/1-4: Switch Tab | Q: Quit[-]",
		snap.Timestamp.Format("15:04:05"),
		snap.CPU.TotalPercent,
		snap.Memory.RAMPercent,
		alertStatus,
	)
	a.summaryView.SetText(summary)
}

func (a *App) renderCPUView(snap metrics.SystemSnapshot) {
	var sb strings.Builder

	// CPU Alert Highlight
	cpuAlert := a.engine.IsRuleActive("High CPU Usage") || a.isMetricAlertActive("cpu")
	cpuHeaderColor := "cyan"
	if cpuAlert {
		cpuHeaderColor = "red"
		sb.WriteString("[red:bold]⚠ WARNING: CPU HIGH USAGE ALERT IS ACTIVE![-:-]\n\n")
	}

	totalHist := a.collector.CPUHistory.Data()
	spark := RenderSparkline(totalHist, 0, 100, 50)
	sb.WriteString(fmt.Sprintf("[%s]Total CPU Usage: %5.1f%% [%s] %s[-]\n\n",
		cpuHeaderColor, snap.CPU.TotalPercent, getBarColor(snap.CPU.TotalPercent), spark))

	sb.WriteString("[yellow]Per-Core CPU Usage:[-]\n")
	for i, corePct := range snap.CPU.CoresPercent {
		barColor := getBarColor(corePct)
		barLen := int(corePct / 5) // 20 chars max
		bar := strings.Repeat("█", barLen) + strings.Repeat("░", 20-barLen)
		sb.WriteString(fmt.Sprintf("  Core %2d: %5.1f%% [%s%s[-] ]\n", i, corePct, barColor, bar))
	}

	a.cpuView.SetText(sb.String())
}

func (a *App) renderMemDiskView(snap metrics.SystemSnapshot) {
	var sb strings.Builder

	// RAM Section
	ramAlert := a.isMetricAlertActive("memory") || a.isMetricAlertActive("ram")
	ramColor := "green"
	if ramAlert {
		ramColor = "red"
		sb.WriteString("[red:bold]⚠ WARNING: RAM USAGE ALERT IS ACTIVE![-:-]\n")
	}

	ramHist := a.collector.RAMHistory.Data()
	ramSpark := RenderSparkline(ramHist, 0, 100, 40)
	sb.WriteString(fmt.Sprintf("\n[%s]RAM Usage: %5.1f%% [%s] (%s / %s)[-]\n",
		ramColor, snap.Memory.RAMPercent, ramSpark, FormatBytes(snap.Memory.UsedRAM), FormatBytes(snap.Memory.TotalRAM)))

	// Swap Section
	swapHist := a.collector.SwapHistory.Data()
	swapSpark := RenderSparkline(swapHist, 0, 100, 40)
	sb.WriteString(fmt.Sprintf("[green]Swap Usage: %5.1f%% [%s] (%s / %s)[-]\n\n",
		snap.Memory.SwapPercent, swapSpark, FormatBytes(snap.Memory.UsedSwap), FormatBytes(snap.Memory.TotalSwap)))

	// Storage Section
	diskAlert := a.isMetricAlertActive("disk")
	diskColor := "yellow"
	if diskAlert {
		diskColor = "red"
		sb.WriteString("[red:bold]⚠ WARNING: DISK USAGE ALERT IS ACTIVE![-:-]\n")
	}
	sb.WriteString(fmt.Sprintf("[%s]Disk Partitions / Mounts:[-]\n", diskColor))

	for _, d := range snap.Disks {
		rowColor := getBarColor(d.UsedPercent)
		if diskAlert {
			rowColor = "[red]"
		}
		sb.WriteString(fmt.Sprintf("  %-15s (%s, %s): %5.1f%% used | %s free / %s total %s\n",
			d.Mountpoint, d.Device, d.Fstype, d.UsedPercent, FormatBytes(d.Free), FormatBytes(d.Total), rowColor))
	}

	a.memDiskView.SetText(sb.String())
}

func (a *App) renderNetView(snap metrics.SystemSnapshot) {
	var sb strings.Builder

	netAlert := a.isMetricAlertActive("net_rx") || a.isMetricAlertActive("net_tx")
	if netAlert {
		sb.WriteString("[red:bold]⚠ WARNING: NETWORK THRESHOLD ALERT IS ACTIVE![-:-]\n\n")
	}

	sb.WriteString(fmt.Sprintf("%-12s | %-12s | %-12s | %-20s | %-20s\n",
		"Interface", "Rx Speed", "Tx Speed", "Rx History (60s)", "Tx History (60s)"))
	sb.WriteString(strings.Repeat("-", 85) + "\n")

	for _, n := range snap.Networks {
		rxHist := a.collector.NetRxHistory[n.Name].Data()
		txHist := a.collector.NetTxHistory[n.Name].Data()

		rxSpark := RenderSparkline(rxHist, 0, getMax(rxHist), 20)
		txSpark := RenderSparkline(txHist, 0, getMax(txHist), 20)

		sb.WriteString(fmt.Sprintf("%-12s | %-12s | %-12s | [cyan]%s[-] | [magenta]%s[-]\n",
			n.Name,
			FormatSpeed(n.RxSpeedBps),
			FormatSpeed(n.TxSpeedBps),
			rxSpark,
			txSpark,
		))
	}

	a.netView.SetText(sb.String())
}

func (a *App) renderAlertsView(active []alerts.ActiveAlert) {
	var sb strings.Builder

	sb.WriteString("[yellow]Active Triggered Alerts:[-]\n")
	if len(active) == 0 {
		sb.WriteString("  [green]No active alerts.[-]\n")
	} else {
		for _, a := range active {
			sb.WriteString(fmt.Sprintf("  [red:bold]✖ [%s] %s (Metric: %s, Current: %.2f, Threshold: %.2f)[-:-]\n",
				a.TriggeredAt.Format("15:04:05"), a.Message, a.Metric, a.CurrentVal, a.Threshold))
		}
	}

	sb.WriteString("\n[yellow]Alert Event Log:[-]\n")
	events := a.engine.EventLog()
	if len(events) == 0 {
		sb.WriteString("  [darkgray]No log entries yet.[-]\n")
	} else {
		for i := len(events) - 1; i >= 0; i-- { // Newest first
			ev := events[i]
			if strings.Contains(ev, "TRIGGERED") {
				sb.WriteString(fmt.Sprintf("  [red]%s[-]\n", ev))
			} else {
				sb.WriteString(fmt.Sprintf("  [green]%s[-]\n", ev))
			}
		}
	}

	a.alertsView.SetText(sb.String())
}

func (a *App) isMetricAlertActive(metric string) bool {
	for _, active := range a.engine.ActiveAlerts() {
		if strings.EqualFold(active.Metric, metric) {
			return true
		}
	}
	return false
}

func getBarColor(pct float64) string {
	if pct >= 80 {
		return "[red]"
	} else if pct >= 60 {
		return "[yellow]"
	}
	return "[green]"
}

func getMax(data []float64) float64 {
	max := 1.0
	for _, v := range data {
		if v > max {
			max = v
		}
	}
	return max
}
