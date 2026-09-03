# Known Issues & Trade-offs

1. **Windows Disk Metrics Permissions**: On some Windows environments, collecting per-disk performance counters may require administrative privileges or specific performance counter permissions. `gopsutil` handles permission errors gracefully by returning partial disk info if disk IOCounters are restricted.
2. **Virtual Network Interfaces**: On Linux, virtual interfaces like `docker0`, `veth*`, or `br-*` can produce high traffic counts or clutter the UI. Filters can be added in `configs/config.yaml` or interface listing if necessary.
