package clock

import "time"

// Clock provides an interface for time operations to allow deterministic testing.
type Clock interface {
	Now() time.Time
	After(d time.Duration) <-chan time.Time
}

// RealClock implements Clock using the system time.
type RealClock struct{}

func NewRealClock() RealClock {
	return RealClock{}
}

func (RealClock) Now() time.Time {
	return time.Now()
}

func (RealClock) After(d time.Duration) <-chan time.Time {
	return time.After(d)
}

// MockClock implements Clock for testing.
type MockClock struct {
	now time.Time
}

func NewMockClock(start time.Time) *MockClock {
	if start.IsZero() {
		start = time.Date(2025, 1, 1, 12, 0, 0, 0, time.UTC)
	}
	return &MockClock{now: start}
}

func (m *MockClock) Now() time.Time {
	return m.now
}

func (m *MockClock) After(d time.Duration) <-chan time.Time {
	ch := make(chan time.Time, 1)
	ch <- m.now.Add(d)
	return ch
}

func (m *MockClock) Advance(d time.Duration) {
	m.now = m.now.Add(d)
}

func (m *MockClock) Set(t time.Time) {
	m.now = t
}
