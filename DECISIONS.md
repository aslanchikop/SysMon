# Architecture & Design Decisions

## 1. Metrics Collection Library Choice
**Decision:** Selected `github.com/shirou/gopsutil/v3` over pure raw `/proc` parsing.
**Rationale:**
- Cross-platform support: `gopsutil` natively abstracts system metrics collection across both Linux and Windows.
- No CGO requirement: `gopsutil` operates with `CGO_ENABLED=0`, making cross-compilation straightforward via `GOOS=linux GOARCH=amd64` and `GOOS=windows GOARCH=amd64`.
- Reliability and maintainability: `gopsutil` handles OS API edge cases (Windows performance counters, Linux sysfs variations) far better than custom implementations without adding external binary dependencies.

## 2. TUI Library Choice
**Decision:** Selected `github.com/rivo/tview` with `github.com/gdamore/tcell/v2`.
**Rationale:**
- High-level layout components (Flex, Grid, Pages, TextView, Table) make tabbed multi-view layout implementation clean and modular.
- Flicker-free updates: `tview` provides `QueueUpdateDraw()` which schedules thread-safe updates and batch-renders frame changes without full terminal clears.
- Clean terminal teardown: handles raw mode restoration properly on shutdown (`app.Stop()`).

## 3. Sparkline Rendering Approach
**Decision:** Built custom sparkline generator using Unicode block characters (`  ▂▃▄▅▆▇█`).
**Rationale:**
- Lightweight, zero extra dependencies.
- Allows rendering 60-second metrics history in compact ASCII/Unicode single-line rows or multi-height graphs.

## 4. Alert Engine & Time Abstraction
**Decision:** Introduced `clock.Clock` interface for all time operations in the alert engine.
**Rationale:**
- Enables deterministic unit tests for time-based rules (e.g. "CPU > 80% for 30s") without using `time.Sleep`.
- Fully decouples alert logic from wall clock execution.
