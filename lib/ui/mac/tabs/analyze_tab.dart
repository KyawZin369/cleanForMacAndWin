import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mole_ui/core/logic/analyze_controller.dart';
import 'package:mole_ui/core/models/analyze_snapshot.dart';
import 'package:mole_ui/core/utils/format_bytes.dart';

class AnalyzeTab extends StatefulWidget {
  const AnalyzeTab({super.key, required this.controller});

  final AnalyzeController controller;

  @override
  State<AnalyzeTab> createState() => _AnalyzeTabState();
}

class _AnalyzeTabState extends State<AnalyzeTab> {
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
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AnalyzeHeader(controller: controller),
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

class _AnalyzeHeader extends StatelessWidget {
  const _AnalyzeHeader({required this.controller});

  final AnalyzeController controller;

  @override
  Widget build(BuildContext context) {
    final freeLabel = controller.freeBytes != null
        ? ' (${formatBytes(controller.freeBytes!)} free)'
        : '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: controller.canGoBack && !controller.isLoading
                    ? controller.goBack
                    : null,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              Expanded(
                child: Text(
                  'Analyze Disk$freeLabel',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: controller.isLoading
                    ? null
                    : () => controller.openInFinder(),
                icon: const Icon(Icons.folder_open_outlined, size: 18),
                label: const Text('Open in Finder'),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Refresh',
                onPressed: controller.isLoading ? null : controller.refresh,
                icon: controller.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreadcrumbBar extends StatelessWidget {
  const _BreadcrumbBar({required this.controller});

  final AnalyzeController controller;

  @override
  Widget build(BuildContext context) {
    final segments = controller.breadcrumbSegments;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < segments.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: const Color(0xFF1C1C1E).withValues(alpha: 0.35),
                      ),
                    ),
                  InkWell(
                    onTap: controller.isLoading
                        ? null
                        : () => controller.navigateToBreadcrumb(i),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Text(
                        segments[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              i == segments.length - 1 ? FontWeight.w600 : FontWeight.w500,
                          color: i == segments.length - 1
                              ? const Color(0xFF007AFF)
                              : const Color(0xFF1C1C1E).withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
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
        child: Text(
          controller.errorMessage!,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFFFF3B30).withValues(alpha: 0.85),
          ),
        ),
      );
    }

    final snapshot = controller.snapshot;
    if (snapshot == null || snapshot.entries.isEmpty) {
      return Center(
        child: Text(
          'No items to display.',
          style: TextStyle(
            color: const Color(0xFF1C1C1E).withValues(alpha: 0.45),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.52),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
          ),
          child: Column(
            children: [
              _ListHeader(totalSize: snapshot.totalSize),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: snapshot.entries.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                  itemBuilder: (context, index) {
                    final entry = snapshot.entries[index];
                    return _AnalyzeRow(
                      entry: entry,
                      totalSize: snapshot.totalSize,
                      onOpen: entry.isDir
                          ? () => controller.openEntry(entry)
                          : null,
                      onReveal: () => controller.openInFinder(entry.path),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.totalSize});

  final int totalSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              'Name',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C1C1E).withValues(alpha: 0.45),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Size',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C1C1E).withValues(alpha: 0.45),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Share',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C1C1E).withValues(alpha: 0.45),
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

class _AnalyzeRow extends StatelessWidget {
  const _AnalyzeRow({
    required this.entry,
    required this.totalSize,
    required this.onReveal,
    this.onOpen,
  });

  final AnalyzeEntry entry;
  final int totalSize;
  final VoidCallback? onOpen;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    final share = totalSize > 0 ? entry.size / totalSize : 0.0;
    final sharePercent = (share * 100).clamp(0.0, 100.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        onDoubleTap: onReveal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    Icon(
                      _iconForEntry(entry),
                      size: 18,
                      color: entry.insight
                          ? const Color(0xFFFF9500)
                          : const Color(0xFF007AFF),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1C1C1E),
                            ),
                          ),
                          if (entry.insight || entry.cleanable)
                            Text(
                              entry.cleanable ? 'Cleanable insight' : 'Insight',
                              style: TextStyle(
                                fontSize: 11,
                                color: const Color(0xFF1C1C1E)
                                    .withValues(alpha: 0.45),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  formatBytes(entry.size),
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF1C1C1E).withValues(alpha: 0.7),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: share,
                          minHeight: 8,
                          backgroundColor:
                              Colors.black.withValues(alpha: 0.06),
                          color: const Color(0xFF007AFF),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 44,
                      child: Text(
                        '${sharePercent.toStringAsFixed(1)}%',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF1C1C1E).withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Reveal in Finder',
                onPressed: onReveal,
                icon: Icon(
                  Icons.open_in_new_rounded,
                  size: 18,
                  color: const Color(0xFF1C1C1E).withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForEntry(AnalyzeEntry entry) {
    if (entry.insight) return Icons.visibility_outlined;
    if (entry.isDir) return Icons.folder_rounded;
    return Icons.insert_drive_file_outlined;
  }
}
