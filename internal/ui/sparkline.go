package ui

import (
	"fmt"
	"math"
)

var sparklineBlocks = []rune{' ', ' ', '▂', '▃', '▄', '▅', '▆', '▇', '█'}

// RenderSparkline converts a slice of values into an ASCII/Unicode sparkline string.
func RenderSparkline(data []float64, minVal, maxVal float64, width int) string {
	if width <= 0 {
		width = 60
	}

	var sampleData []float64
	if len(data) > width {
		sampleData = data[len(data)-width:]
	} else {
		sampleData = make([]float64, width)
		padding := width - len(data)
		for i := 0; i < padding; i++ {
			sampleData[i] = minVal
		}
		copy(sampleData[padding:], data)
	}

	if maxVal <= minVal {
		maxVal = 100.0
		minVal = 0.0
	}

	var runes []rune
	rangeVal := maxVal - minVal

	for _, v := range sampleData {
		if v < minVal {
			v = minVal
		}
		if v > maxVal {
			v = maxVal
		}

		normalized := (v - minVal) / rangeVal
		index := int(math.Floor(normalized * float64(len(sparklineBlocks)-1)))
		if index < 0 {
			index = 0
		}
		if index >= len(sparklineBlocks) {
			index = len(sparklineBlocks) - 1
		}

		runes = append(runes, sparklineBlocks[index])
	}

	return string(runes)
}

// FormatBytes formats bytes into human readable format.
func FormatBytes(b uint64) string {
	const unit = 1024
	if b < unit {
		return fmt.Sprintf("%d B", b)
	}
	div, exp := uint64(unit), 0
	for n := b / unit; n >= unit; n /= unit {
		div *= unit
		exp++
	}
	return fmt.Sprintf("%.1f %cB", float64(b)/float64(div), "KMGTPE"[exp])
}

// FormatSpeed formats bytes per second into human readable bandwidth speed.
func FormatSpeed(bps float64) string {
	if bps < 1024 {
		return fmt.Sprintf("%.0f B/s", bps)
	}
	if bps < 1024*1024 {
		return fmt.Sprintf("%.1f KB/s", bps/1024)
	}
	if bps < 1024*1024*1024 {
		return fmt.Sprintf("%.1f MB/s", bps/(1024*1024))
	}
	return fmt.Sprintf("%.2f GB/s", bps/(1024*1024*1024))
}
