import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mole_ui/core/logic/status_controller.dart';
import 'package:mole_ui/core/models/system_status.dart';
import 'package:mole_ui/core/utils/format_bytes.dart';
import 'package:mole_ui/core/utils/format_rates.dart';

class StatusTab extends StatefulWidget {
  const StatusTab({super.key, required this.controller});

  final StatusController controller;

  @override
  State<StatusTab> createState() => _StatusTabState();
}

class _StatusTabState extends State<StatusTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.startMonitoring();
    });
  }

  @override
  void dispose() {
    widget.controller.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;

        if (controller.isLoading && controller.status == null) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(strokeWidth: 2.5),
                SizedBox(height: 16),
                Text(
                  'Loading system status…',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF636366),
                  ),
                ),
              ],
            ),
          );
        }

        if (controller.errorMessage != null && controller.status == null) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 40,
                      color: Color(0xFFFF3B30),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      controller.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF636366),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: controller.refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final status = controller.status;
        if (status == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatusHeader(
                status: status,
                isRefreshing: controller.isLoading,
                onRefresh: controller.refresh,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    _MemorySection(memory: status.memory),
                    const SizedBox(height: 12),
                    _DiskSection(
                      disks: status.disks,
                      trashBytes: status.trashBytes,
                      diskIo: status.diskIo,
                    ),
                    const SizedBox(height: 12),
                    _PowerSection(batteries: status.batteries),
                    const SizedBox(height: 12),
                    _ProcessesSection(processes: status.topProcesses),
                    const SizedBox(height: 12),
                    _NetworkSection(
                      network: status.network,
                      proxy: status.proxy,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({
    required this.status,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final SystemStatus status;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final scoreColor = _healthColor(status.healthScore);

    return _GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scoreColor.withValues(alpha: 0.12),
              border: Border.all(color: scoreColor.withValues(alpha: 0.35)),
            ),
            alignment: Alignment.center,
            child: Text(
              '${status.healthScore}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: scoreColor,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.host,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status.healthScoreMessage.isNotEmpty
                      ? status.healthScoreMessage
                      : 'Uptime ${status.uptime}',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF636366).withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${status.cpuUsage.toStringAsFixed(1)}% CPU',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 4),
              IconButton(
                tooltip: 'Refresh',
                visualDensity: VisualDensity.compact,
                onPressed: isRefreshing ? null : onRefresh,
                icon: isRefreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _healthColor(int score) {
    if (score >= 80) return const Color(0xFF34C759);
    if (score >= 50) return const Color(0xFFFF9500);
    return const Color(0xFFFF3B30);
  }
}

class _MemorySection extends StatelessWidget {
  const _MemorySection({required this.memory});

  final MemoryStatus memory;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(icon: Icons.memory_rounded, label: 'Memory'),
          const SizedBox(height: 14),
          _MetricRow(
            label: 'Swap',
            value:
                '${memory.swapPercent.toStringAsFixed(1)}%  ${formatBytes(memory.swapUsedBytes)}/${formatBytes(memory.swapTotalBytes)}',
            fraction: memory.swapPercent / 100,
            barColor: const Color(0xFFFF9500),
          ),
          const SizedBox(height: 10),
          _InfoLine(
            label: 'Total',
            value:
                '${formatBytes(memory.usedBytes)} / ${formatBytes(memory.totalBytes)}',
          ),
          const SizedBox(height: 4),
          _InfoLine(
            label: 'Avail',
            value: formatBytes(memory.availableBytes),
          ),
          const SizedBox(height: 10),
          _MetricRow(
            label: 'Used',
            value: '${memory.usedPercent.toStringAsFixed(1)}%',
            fraction: memory.usedPercent / 100,
            barColor: const Color(0xFF007AFF),
          ),
        ],
      ),
    );
  }
}

class _DiskSection extends StatelessWidget {
  const _DiskSection({
    required this.disks,
    required this.trashBytes,
    required this.diskIo,
  });

  final List<DiskStatus> disks;
  final int trashBytes;
  final DiskIoStatus diskIo;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(icon: Icons.storage_rounded, label: 'Disk'),
          const SizedBox(height: 14),
          for (final disk in disks) ...[
            _MetricRow(
              label: disk.label,
              value:
                  '${formatBytes(disk.usedBytes)} used, ${formatBytes(disk.freeBytes)} free',
              fraction: disk.usedPercent / 100,
              barColor: disk.usedPercent >= 90
                  ? const Color(0xFFFF3B30)
                  : disk.isExternal
                      ? const Color(0xFF5856D6)
                      : const Color(0xFF007AFF),
            ),
            if (disk != disks.last) const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          _InfoLine(label: 'Trash', value: formatBytes(trashBytes)),
          const SizedBox(height: 10),
          _MetricRow(
            label: 'Read',
            value: formatBytesPerSecond(diskIo.readRate),
            fraction: _ioFraction(diskIo.readRate),
            barColor: const Color(0xFF34C759),
          ),
          const SizedBox(height: 8),
          _MetricRow(
            label: 'Write',
            value: formatBytesPerSecond(diskIo.writeRate),
            fraction: _ioFraction(diskIo.writeRate),
            barColor: const Color(0xFF5AC8FA),
          ),
        ],
      ),
    );
  }

  double _ioFraction(double rate) {
    if (rate <= 0) return 0;
    // Scale roughly to 100 MB/s for visual bar fill.
    return (rate / (100 * 1024 * 1024)).clamp(0.05, 1.0);
  }
}

class _PowerSection extends StatelessWidget {
  const _PowerSection({required this.batteries});

  final List<BatteryStatus> batteries;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(icon: Icons.battery_charging_full_rounded, label: 'Power'),
          const SizedBox(height: 14),
          if (batteries.isEmpty)
            Text(
              'No battery',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF636366).withValues(alpha: 0.95),
              ),
            )
          else
            for (final battery in batteries) ...[
              _MetricRow(
                label: battery.name,
                value: _batteryLabel(battery),
                fraction: battery.chargePercent / 100,
                barColor: battery.isCharging
                    ? const Color(0xFF34C759)
                    : const Color(0xFF007AFF),
              ),
              if (battery != batteries.last) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  String _batteryLabel(BatteryStatus battery) {
    final parts = <String>['${battery.chargePercent}%'];
    if (battery.isCharging) parts.add('charging');
    if (battery.timeRemaining.isNotEmpty) parts.add(battery.timeRemaining);
    return parts.join(' · ');
  }
}

class _ProcessesSection extends StatelessWidget {
  const _ProcessesSection({required this.processes});

  final List<ProcessStatus> processes;

  @override
  Widget build(BuildContext context) {
    final top = processes.take(5).toList();

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(icon: Icons.apps_rounded, label: 'Processes'),
          const SizedBox(height: 14),
          if (top.isEmpty)
            Text(
              'No process data',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF636366).withValues(alpha: 0.95),
              ),
            )
          else
            for (final process in top) ...[
              _MetricRow(
                label: process.displayName,
                value: '${process.cpu.toStringAsFixed(1)}%',
                fraction: (process.cpu / 100).clamp(0, 1),
                barColor: const Color(0xFFAF52DE),
              ),
              if (process != top.last) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _NetworkSection extends StatelessWidget {
  const _NetworkSection({
    required this.network,
    required this.proxy,
  });

  final NetworkStatus network;
  final ProxyStatus? proxy;

  @override
  Widget build(BuildContext context) {
    final proxyLabel = _proxyLabel(proxy);

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(icon: Icons.swap_vert_rounded, label: 'Network'),
          const SizedBox(height: 14),
          _MetricRow(
            label: 'Down',
            value: formatMegabytesPerSecond(network.downloadMbps),
            fraction: _networkFraction(network.downloadMbps),
            barColor: const Color(0xFF34C759),
          ),
          const SizedBox(height: 8),
          _MetricRow(
            label: 'Up',
            value: formatMegabytesPerSecond(network.uploadMbps),
            fraction: _networkFraction(network.uploadMbps),
            barColor: const Color(0xFF007AFF),
          ),
          if (network.primaryIp.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoLine(label: 'IP', value: network.primaryIp),
          ],
          if (proxyLabel != null) ...[
            const SizedBox(height: 8),
            _InfoLine(label: 'Proxy', value: proxyLabel),
          ],
        ],
      ),
    );
  }

  double _networkFraction(double mbps) {
    if (mbps <= 0) return 0;
    return (mbps / 50).clamp(0.05, 1.0);
  }

  String? _proxyLabel(ProxyStatus? proxy) {
    if (proxy == null) return null;
    if (!proxy.enabled) return 'Disabled';
    final type = proxy.type.isNotEmpty ? proxy.type : 'Proxy';
    final host = proxy.host.isNotEmpty ? ' ${proxy.host}' : '';
    return '$type$host';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF007AFF)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C1C1E),
          ),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    required this.fraction,
    required this.barColor,
  });

  final String label;
  final String value;
  final double fraction;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1C1C1E),
                ),
              ),
            ),
            Expanded(
              child: _ProgressBar(
                fraction: fraction.clamp(0, 1),
                color: barColor,
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 168,
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF636366).withValues(alpha: 0.95),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1C1C1E),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF636366).withValues(alpha: 0.95),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 8,
        child: Stack(
          children: [
            Container(color: const Color(0xFFE5E5EA)),
            FractionallySizedBox(
              widthFactor: fraction,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.85),
                      color,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
          ),
          child: child,
        ),
      ),
    );
  }
}
