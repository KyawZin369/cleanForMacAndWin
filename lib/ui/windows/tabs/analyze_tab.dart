import 'package:flutter/material.dart';
import 'package:mole_ui/core/logic/analyze_controller.dart';
import 'package:mole_ui/core/models/analyze_snapshot.dart';
import 'package:mole_ui/core/utils/format_bytes.dart';
import 'package:mole_ui/ui/windows/widgets/fluent_widgets.dart';

class WindowsAnalyzeTab extends StatefulWidget {
  const WindowsAnalyzeTab({super.key, required this.controller});

  final AnalyzeController controller;

  @override
  State<WindowsAnalyzeTab> createState() => _WindowsAnalyzeTabState();
}

class _WindowsAnalyzeTabState extends State<WindowsAnalyzeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WindowsCard(
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: controller.canGoBack && !controller.isLoading
                          ? controller.goBack
                          : null,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Expanded(
                      child: Text(
                        controller.freeBytes != null
                            ? 'Analyze disk (${formatBytes(controller.freeBytes!)} free)'
                            : 'Analyze disk',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF323130),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: controller.isLoading
                          ? null
                          : () => controller.openInFinder(),
                      icon: const Icon(Icons.folder_open_outlined, size: 18),
                      label: Text(controller.revealLabel),
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
              _BreadcrumbBar(controller: controller),
              const SizedBox(height: 12),
              Expanded(child: _AnalyzeBody(controller: controller)),
            ],
          ),
        );
      },
    );
  }
}

class _BreadcrumbBar extends StatelessWidget {
  const _BreadcrumbBar({required this.controller});

  final AnalyzeController controller;

  @override
  Widget build(BuildContext context) {
    final segments = controller.breadcrumbSegments;

    return WindowsCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            if (i > 0)
              const Icon(Icons.chevron_right, size: 16, color: Color(0xFF8A8886)),
            TextButton(
              onPressed: controller.isLoading
                  ? null
                  : () => controller.navigateToBreadcrumb(i),
              style: TextButton.styleFrom(
                foregroundColor: i == segments.length - 1
                    ? const Color(0xFF323130)
                    : const Color(0xFF0078D4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: Text(segments[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnalyzeBody extends StatelessWidget {
  const _AnalyzeBody({required this.controller});

  final AnalyzeController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading && controller.snapshot == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage != null && controller.snapshot == null) {
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

    final entries = controller.snapshot?.entries ?? [];
    if (entries.isEmpty) {
      return const Center(
        child: Text('No entries', style: TextStyle(color: Color(0xFF605E5C))),
      );
    }

    return WindowsCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        itemCount: entries.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEDEBE9)),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return _EntryRow(entry: entry, controller: controller);
        },
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, required this.controller});

  final AnalyzeEntry entry;
  final AnalyzeController controller;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: entry.isDir && !controller.isLoading
            ? () => controller.openEntry(entry)
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                entry.isDir ? Icons.folder_outlined : Icons.insert_drive_file_outlined,
                color: const Color(0xFF0078D4),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.name,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF323130),
                  ),
                ),
              ),
              Text(
                formatBytes(entry.size),
                style: const TextStyle(fontSize: 12, color: Color(0xFF605E5C)),
              ),
              if (entry.isDir) ...[
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Color(0xFF8A8886)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
