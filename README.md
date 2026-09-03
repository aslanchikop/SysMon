# SysMon - Terminal System Monitor in Go

SysMon — это автономный терминальный системный монитор (TUI), написанный на Go без использования CGO.

## Особенности
- **Сбор метрик**:
  - CPU: загрузка общая и по каждому ядру.
  - Память: RAM и Swap (всего, занято, свободно, процент).
  - Диски: точки монтирования, объем, свободной место, использование.
  - Сеть: входящая и исходящая скорость (B/s, KB/s, MB/s) и объемы трафика.
- **TUI-интерфейс (tview / tcell)**:
  - ASCII/Unicode графики истории загрузки (sparkline за 60 секунд).
  - Навигация по вкладкам клавишей `Tab`, `Shift+Tab` или цифрами `1`, `2`, `3`, `4`.
  - Обновление раз в секунду без мигания экрана (`QueueUpdateDraw`).
- **Система алертов**:
  - Гибкая настройка правил в `configs/config.yaml`.
  - Отслеживание длительности превышения порога.
  - Запись сработавших и разрешенных алертов в файл логов.
  - Подсветка проблемных строк в UI.
- **Graceful Shutdown**:
  - Перехват `Ctrl+C` (`SIGINT`/`SIGTERM`) с чистым восстановлением терминала.

---

## Требования
- Go 1.20+

---

## Сборка и запуск

### Запуск тестов и проверка качества кода
```bash
make test
make vet
```

### Сборка под Linux и Windows
Единый Makefile собирает бинарники без использования CGO (`CGO_ENABLED=0`):

```bash
make all
```

Бинарники будут созданы в папке `bin/`:
- `bin/sysmon-linux-amd64`
- `bin/sysmon-windows-amd64.exe`

### Локальная сборка и запуск
```bash
make build
./bin/sysmon
```

Или напрямую через `go`:
```bash
go run ./cmd/sysmon -config configs/config.yaml -log sysmon_alerts.log
```

---

## Конфигурация алертов (`configs/config.yaml`)

Пример файла конфигурации:
```yaml
rules:
  - name: "High CPU Usage"
    metric: "cpu"
    operator: ">"
    threshold: 80.0
    duration: 5s
    message: "CPU usage exceeded 80% for 5 seconds"

  - name: "High Memory Usage"
    metric: "memory"
    operator: ">"
    threshold: 85.0
    duration: 10s
    message: "RAM usage exceeded 85%"

  - name: "High Disk Usage"
    metric: "disk"
    target: "/"
    operator: ">="
    threshold: 90.0
    duration: 0s
    message: "Root disk partition usage is above 90%"
```

---

## Навигация в UI
- `Tab` / `Shift+Tab` — переключение между вкладками.
- `1` — CPU (общая загрузка + ядра + sparkline истории).
- `2` — RAM / Swap / Disks.
- `3` — Network interfaces (скорость Rx/Tx + sparkline).
- `4` — Alerts & Event Log.
- `Q` / `Ctrl+C` — выход из приложения.
