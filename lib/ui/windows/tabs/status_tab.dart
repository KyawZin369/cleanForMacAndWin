import 'package:flutter/material.dart';
import 'package:mole_ui/core/logic/status_controller.dart';
import 'package:mole_ui/core/utils/format_bytes.dart';
import 'package:mole_ui/core/utils/format_rates.dart';
import 'package:mole_ui/ui/windows/widgets/fluent_widgets.dart';

class WindowsStatusTab extends StatefulWidget {
  const WindowsStatusTab({super.key, required this.controller});

  final StatusController controller;

  @override
  State<WindowsStatusTab> createState() => _WindowsStatusTabState();
}

class _WindowsStatusTabState extends State<WindowsStatusTab> {
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
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage != null && controller.status == null) {
          return Center(
            child: WindowsCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(controller.errorMessage!),
                  const SizedBox(height: 12),
                  WindowsPrimaryButton(
                    label: 'Retry',
                    onPressed: controller.refresh,
                  ),
                ],
              ),
            ),
          );
        }

        final status = controller.status;
        if (status == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              WindowsCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status.host.isNotEmpty ? status.host : 'System status',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF323130),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Health ${status.healthScore} · ${status.healthScoreMessage}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF605E5C),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed:
                          controller.isLoading ? null : controller.refresh,
                      icon: controller.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _MetricCard(
                title: 'CPU',
                primary: '${status.cpuUsage.toStringAsFixed(1)}% load',
                secondary: status.uptime.isNotEmpty
                    ? 'Uptime ${status.uptime}'
                    : 'Live system monitor',
                progress: status.cpuUsage / 100,
              ),
              const SizedBox(height: 12),
              _MetricCard(
                title: 'Memory',
                primary: '${status.memory.usedPercent.toStringAsFixed(1)}% used',
                secondary:
                    '${formatBytes(status.memory.usedBytes)} / ${formatBytes(status.memory.totalBytes)}',
                progress: status.memory.usedPercent / 100,
              ),
              const SizedBox(height: 12),
              if (status.disks.isNotEmpty)
                _MetricCard(
                  title: 'Disk',
                  primary: status.disks.first.label,
                  secondary:
                      '${formatBytes(status.disks.first.usedBytes)} / ${formatBytes(status.disks.first.totalBytes)}',
                  progress: status.disks.first.usedPercent / 100,
                ),
              const SizedBox(height: 12),
              _MetricCard(
                title: 'Network',
                primary: 'Down ${formatMegabytesPerSecond(status.network.downloadMbps)}',
                secondary: 'Up ${formatMegabytesPerSecond(status.network.uploadMbps)}',
                progress: null,
              ),
              const SizedBox(height: 12),
              if (status.topProcesses.isNotEmpty)
                WindowsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Top processes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF323130),
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final process in status.topProcesses.take(8))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  process.displayName,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              Text(
                                '${process.cpu.toStringAsFixed(1)}% CPU',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF605E5C),
                                ),
                              ),
                            ],
                          ),
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.primary,
    required this.secondary,
    required this.progress,
  });

  final String title;
  final String primary;
  final String secondary;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return WindowsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF605E5C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            primary,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF323130),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            secondary,
            style: const TextStyle(fontSize: 13, color: Color(0xFF605E5C)),
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: const Color(0xFFEDEBE9),
                color: const Color(0xFF0078D4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
