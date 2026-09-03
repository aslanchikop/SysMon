package alerts

import (
	"fmt"
	"io"
	"log"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"

	"gopkg.in/yaml.v3"
	"sysmon/internal/clock"
	"sysmon/internal/metrics"
)

// Rule defines a single alert rule loaded from configuration.
type Rule struct {
	Name      string        `yaml:"name"`
	Metric    string        `yaml:"metric"`    // cpu, memory, swap, disk, net_rx, net_tx
	Target    string        `yaml:"target"`    // interface or mountpoint if applicable, or empty / "total"
	Operator  string        `yaml:"operator"`  // >, >=, <, <=, ==
	Threshold float64       `yaml:"threshold"` // e.g., 80.0
	Duration  time.Duration `yaml:"duration"`  // e.g., 30s
	Message   string        `yaml:"message"`
}

// Config wraps a slice of Rules.
type Config struct {
	Rules []Rule `yaml:"rules"`
}

// LoadConfig parses a YAML configuration file or buffer.
func LoadConfig(r io.Reader) (*Config, error) {
	var cfg Config
	decoder := yaml.NewDecoder(r)
	if err := decoder.Decode(&cfg); err != nil {
		return nil, fmt.Errorf("failed to parse alert yaml config: %w", err)
	}
	return &cfg, nil
}

func LoadConfigFile(filepath string) (*Config, error) {
	f, err := os.Open(filepath)
	if err != nil {
		return nil, fmt.Errorf("failed to open alert config file %s: %w", filepath, err)
	}
	defer f.Close()
	return LoadConfig(f)
}

// ActiveAlert represents an currently active alert.
type ActiveAlert struct {
	RuleName    string
	Metric      string
	Target      string
	CurrentVal  float64
	Threshold   float64
	TriggeredAt time.Time
	Message     string
}

// Engine evaluates alert rules against metric snapshots.
type Engine struct {
	rules      []Rule
	clk        clock.Clock
	logger     *log.Logger
	logFile    *os.File
	mu         sync.RWMutex

	// Map rule name -> timestamp when metric first crossed threshold
	breachStart map[string]time.Time
	// Active triggered alerts
	activeAlerts map[string]ActiveAlert
	// History of triggered alert events for UI display
	eventLog []string
}

func NewEngine(cfg *Config, clk clock.Clock, logFilePath string) (*Engine, error) {
	if clk == nil {
		clk = clock.NewRealClock()
	}

	rules := []Rule{}
	if cfg != nil {
		rules = cfg.Rules
	}

	var logger *log.Logger
	var f *os.File
	if logFilePath != "" {
		var err error
		f, err = os.OpenFile(logFilePath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
		if err != nil {
			return nil, fmt.Errorf("failed to open alert log file: %w", err)
		}
		logger = log.New(f, "[ALERT] ", log.LstdFlags)
	} else {
		logger = log.New(io.Discard, "", 0)
	}

	return &Engine{
		rules:        rules,
		clk:          clk,
		logger:       logger,
		logFile:      f,
		breachStart:  make(map[string]time.Time),
		activeAlerts: make(map[string]ActiveAlert),
		eventLog:     make([]string, 0),
	}, nil
}

func (e *Engine) Close() error {
	if e.logFile != nil {
		return e.logFile.Close()
	}
	return nil
}

// Evaluate evaluates all configured rules against the given snapshot.
func (e *Engine) Evaluate(snap metrics.SystemSnapshot) []ActiveAlert {
	e.mu.Lock()
	defer e.mu.Unlock()

	now := snap.Timestamp
	if now.IsZero() {
		now = e.clk.Now()
	}

	for _, rule := range e.rules {
		val, matched := getMetricValue(snap, rule.Metric, rule.Target)
		if !matched {
			// Metric/target not found, reset breach start if any
			delete(e.breachStart, rule.Name)
			delete(e.activeAlerts, rule.Name)
			continue
		}

		breached := checkCondition(val, rule.Operator, rule.Threshold)
		if breached {
			start, exists := e.breachStart[rule.Name]
			if !exists {
				e.breachStart[rule.Name] = now
				start = now
			}

			// Check if duration requirement met
			if now.Sub(start) >= rule.Duration {
				if _, alreadyActive := e.activeAlerts[rule.Name]; !alreadyActive {
					msg := rule.Message
					if msg == "" {
						msg = fmt.Sprintf("Rule '%s' breached: %s %s %.2f (current: %.2f)",
							rule.Name, rule.Metric, rule.Operator, rule.Threshold, val)
					}
					alert := ActiveAlert{
						RuleName:    rule.Name,
						Metric:      rule.Metric,
						Target:      rule.Target,
						CurrentVal:  val,
						Threshold:   rule.Threshold,
						TriggeredAt: now,
						Message:     msg,
					}
					e.activeAlerts[rule.Name] = alert

					logEntry := fmt.Sprintf("[%s] TRIGGERED: %s", now.Format("15:04:05"), msg)
					e.logger.Println(logEntry)
					e.eventLog = append(e.eventLog, logEntry)
				} else {
					// Update current value
					a := e.activeAlerts[rule.Name]
					a.CurrentVal = val
					e.activeAlerts[rule.Name] = a
				}
			}
		} else {
			// Condition no longer breached
			if _, wasActive := e.activeAlerts[rule.Name]; wasActive {
				logEntry := fmt.Sprintf("[%s] RESOLVED: Rule '%s' restored to normal (current: %.2f)",
					now.Format("15:04:05"), rule.Name, val)
				e.logger.Println(logEntry)
				e.eventLog = append(e.eventLog, logEntry)
			}
			delete(e.breachStart, rule.Name)
			delete(e.activeAlerts, rule.Name)
		}
	}

	// Return active alerts
	result := make([]ActiveAlert, 0, len(e.activeAlerts))
	for _, a := range e.activeAlerts {
		result = append(result, a)
	}
	return result
}

func (e *Engine) ActiveAlerts() []ActiveAlert {
	e.mu.RLock()
	defer e.mu.RUnlock()

	res := make([]ActiveAlert, 0, len(e.activeAlerts))
	for _, a := range e.activeAlerts {
		res = append(res, a)
	}
	return res
}

func (e *Engine) IsRuleActive(ruleName string) bool {
	e.mu.RLock()
	defer e.mu.RUnlock()
	_, active := e.activeAlerts[ruleName]
	return active
}

func (e *Engine) EventLog() []string {
	e.mu.RLock()
	defer e.mu.RUnlock()

	res := make([]string, len(e.eventLog))
	copy(res, e.eventLog)
	return res
}

func getMetricValue(snap metrics.SystemSnapshot, metric, target string) (float64, bool) {
	switch strings.ToLower(metric) {
	case "cpu":
		if target == "" || target == "total" {
			return snap.CPU.TotalPercent, true
		}
		if strings.HasPrefix(target, "core") {
			coreIdxStr := strings.TrimPrefix(target, "core")
			idx, err := strconv.Atoi(coreIdxStr)
			if err == nil && idx >= 0 && idx < len(snap.CPU.CoresPercent) {
				return snap.CPU.CoresPercent[idx], true
			}
		}
	case "memory", "ram":
		return snap.Memory.RAMPercent, true
	case "swap":
		return snap.Memory.SwapPercent, true
	case "disk":
		for _, d := range snap.Disks {
			if target == "" || d.Mountpoint == target || d.Device == target {
				return d.UsedPercent, true
			}
		}
	case "net_rx":
		for _, n := range snap.Networks {
			if target == "" || n.Name == target {
				return n.RxSpeedBps, true
			}
		}
	case "net_tx":
		for _, n := range snap.Networks {
			if target == "" || n.Name == target {
				return n.TxSpeedBps, true
			}
		}
	}
	return 0, false
}

func checkCondition(val float64, op string, threshold float64) bool {
	switch op {
	case ">":
		return val > threshold
	case ">=":
		return val >= threshold
	case "<":
		return val < threshold
	case "<=":
		return val <= threshold
	case "==", "=":
		return val == threshold
	default:
		return val > threshold
	}
}
