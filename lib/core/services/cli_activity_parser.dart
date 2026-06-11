import 'package:flutter/material.dart';
import 'package:mole_ui/core/logic/cli_activity.dart';
import 'package:mole_ui/core/services/mole_cli_password.dart';

class SectionCatalogEntry {
  const SectionCatalogEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

/// Maps raw CLI section names to friendlier labels for the UI.
class CliSectionCatalog {
  CliSectionCatalog._();

  static const macClean = <String, SectionCatalogEntry>{
    'System': SectionCatalogEntry(
      title: 'System files',
      subtitle: 'Caches, logs, and temporary files',
      icon: Icons.dns_outlined,
    ),
    'User essentials': SectionCatalogEntry(
      title: 'Your essentials',
      subtitle: 'Trash, downloads, and personal caches',
      icon: Icons.person_outline,
    ),
    'App caches': SectionCatalogEntry(
      title: 'App caches',
      subtitle: 'Leftover data from installed apps',
      icon: Icons.apps_outlined,
    ),
    'Browsers': SectionCatalogEntry(
      title: 'Browsers',
      subtitle: 'Browser caches and temporary files',
      icon: Icons.language_outlined,
    ),
    'Cloud & Office': SectionCatalogEntry(
      title: 'Cloud & Office',
      subtitle: 'Sync folders and office app caches',
      icon: Icons.cloud_outlined,
    ),
    'Developer tools': SectionCatalogEntry(
      title: 'Developer tools',
      subtitle: 'Build caches and toolchain data',
      icon: Icons.code_outlined,
    ),
    'Applications': SectionCatalogEntry(
      title: 'Applications',
      subtitle: 'Unused application data',
      icon: Icons.widgets_outlined,
    ),
    'Virtualization': SectionCatalogEntry(
      title: 'Virtual machines',
      subtitle: 'VM and container caches',
      icon: Icons.memory_outlined,
    ),
    'Application Support': SectionCatalogEntry(
      title: 'App data',
      subtitle: 'Application support folders',
      icon: Icons.folder_outlined,
    ),
    'App leftovers': SectionCatalogEntry(
      title: 'App leftovers',
      subtitle: 'Data from apps you removed',
      icon: Icons.delete_sweep_outlined,
    ),
    'Device backups & firmware': SectionCatalogEntry(
      title: 'Device backups',
      subtitle: 'iOS backups and firmware caches',
      icon: Icons.phone_iphone_outlined,
    ),
    'Time Machine': SectionCatalogEntry(
      title: 'Time Machine',
      subtitle: 'Failed backup snapshots',
      icon: Icons.schedule_outlined,
    ),
    'Large files': SectionCatalogEntry(
      title: 'Large files',
      subtitle: 'Finding space-hogging files',
      icon: Icons.insert_drive_file_outlined,
    ),
    'System Data clues': SectionCatalogEntry(
      title: 'Storage hints',
      subtitle: 'What is using your disk space',
      icon: Icons.pie_chart_outline_outlined,
    ),
    'Project artifacts': SectionCatalogEntry(
      title: 'Build artifacts',
      subtitle: 'Old project build outputs',
      icon: Icons.construction_outlined,
    ),
    'External volume': SectionCatalogEntry(
      title: 'External drive',
      subtitle: 'Cleaning connected storage',
      icon: Icons.usb_outlined,
    ),
  };

  static const windowsClean = <String, SectionCatalogEntry>{
    'User temp files': SectionCatalogEntry(
      title: 'Temporary files',
      subtitle: 'User and Windows temp folders',
      icon: Icons.delete_outline,
    ),
    'User essentials': SectionCatalogEntry(
      title: 'Your essentials',
      subtitle: 'Recycle Bin, thumbnails, and recent files',
      icon: Icons.person_outline,
    ),
    'Browser caches': SectionCatalogEntry(
      title: 'Browser caches',
      subtitle: 'Web browser temporary data',
      icon: Icons.language_outlined,
    ),
    'Application caches': SectionCatalogEntry(
      title: 'App caches',
      subtitle: 'Common application caches',
      icon: Icons.apps_outlined,
    ),
    'GPU shader caches': SectionCatalogEntry(
      title: 'GPU shaders',
      subtitle: 'Graphics driver cache files',
      icon: Icons.memory_outlined,
    ),
    'System caches': SectionCatalogEntry(
      title: 'System caches',
      subtitle: 'Font, store, and delivery caches',
      icon: Icons.storage_outlined,
    ),
    'Developer tools': SectionCatalogEntry(
      title: 'Developer tools',
      subtitle: 'npm, pip, Docker, and build caches',
      icon: Icons.code_outlined,
    ),
    'System cleanup': SectionCatalogEntry(
      title: 'System cleanup',
      subtitle: 'Windows system junk files',
      icon: Icons.dns_outlined,
    ),
    'Orphaned app data': SectionCatalogEntry(
      title: 'Orphaned apps',
      subtitle: 'Leftovers from removed programs',
      icon: Icons.delete_sweep_outlined,
    ),
    'Applications': SectionCatalogEntry(
      title: 'Applications',
      subtitle: 'Unused application data',
      icon: Icons.widgets_outlined,
    ),
    'Empty Directories': SectionCatalogEntry(
      title: 'Empty folders',
      subtitle: 'Removing leftover empty directories',
      icon: Icons.folder_off_outlined,
    ),
  };

  static const windowsOptimize = <String, SectionCatalogEntry>{
    'Disk Optimization': SectionCatalogEntry(
      title: 'Disk optimization',
      subtitle: 'TRIM for SSD or defrag for hard drives',
      icon: Icons.storage_outlined,
    ),
    'Windows Search': SectionCatalogEntry(
      title: 'Windows Search',
      subtitle: 'Search service health',
      icon: Icons.search_outlined,
    ),
    'DNS Cache': SectionCatalogEntry(
      title: 'DNS cache',
      subtitle: 'Refreshing network name resolution',
      icon: Icons.wifi_outlined,
    ),
    'Network Optimization': SectionCatalogEntry(
      title: 'Network',
      subtitle: 'Winsock and connection stack refresh',
      icon: Icons.lan_outlined,
    ),
    'Startup Programs': SectionCatalogEntry(
      title: 'Startup programs',
      subtitle: 'Reviewing apps that launch at login',
      icon: Icons.rocket_launch_outlined,
    ),
    'System File Verification': SectionCatalogEntry(
      title: 'System files',
      subtitle: 'Checking protected Windows files',
      icon: Icons.verified_user_outlined,
    ),
    'Disk Health': SectionCatalogEntry(
      title: 'Disk health',
      subtitle: 'Checking drive status and errors',
      icon: Icons.health_and_safety_outlined,
    ),
    'Windows Update': SectionCatalogEntry(
      title: 'Windows Update',
      subtitle: 'Update service and pending downloads',
      icon: Icons.system_update_alt_outlined,
    ),
    'Font Cache Rebuild': SectionCatalogEntry(
      title: 'Font cache',
      subtitle: 'Rebuilding corrupted font caches',
      icon: Icons.font_download_outlined,
    ),
    'Icon Cache Rebuild': SectionCatalogEntry(
      title: 'Icon cache',
      subtitle: 'Refreshing broken desktop icons',
      icon: Icons.image_outlined,
    ),
    'Windows Search Index Reset': SectionCatalogEntry(
      title: 'Search index',
      subtitle: 'Resetting the Windows search database',
      icon: Icons.manage_search_outlined,
    ),
    'Windows Store Cache Reset': SectionCatalogEntry(
      title: 'Microsoft Store',
      subtitle: 'Clearing Store download cache',
      icon: Icons.storefront_outlined,
    ),
    'System Repairs': SectionCatalogEntry(
      title: 'System repairs',
      subtitle: 'Font, icon, store, and search fixes',
      icon: Icons.build_circle_outlined,
    ),
  };

  static const optimize = <String, SectionCatalogEntry>{
    'DNS cache': SectionCatalogEntry(
      title: 'DNS cache',
      subtitle: 'Refreshing network name resolution',
      icon: Icons.wifi_outlined,
    ),
    'Spotlight': SectionCatalogEntry(
      title: 'Spotlight',
      subtitle: 'Search index maintenance',
      icon: Icons.search_outlined,
    ),
    'Memory': SectionCatalogEntry(
      title: 'Memory',
      subtitle: 'Freeing inactive RAM',
      icon: Icons.memory_outlined,
    ),
  };

  static SectionCatalogEntry resolve(
    String rawTitle, {
    Map<String, SectionCatalogEntry>? catalog,
  }) {
    final entry = catalog?[rawTitle];
    if (entry != null) return entry;

    final partial = catalog?.entries.firstWhere(
      (candidate) =>
          rawTitle.toLowerCase().contains(candidate.key.toLowerCase()) ||
          candidate.key.toLowerCase().contains(rawTitle.toLowerCase()),
      orElse: () => MapEntry('', const SectionCatalogEntry(
        title: '',
        subtitle: '',
        icon: Icons.autorenew_outlined,
      )),
    );
    if (partial != null && partial.key.isNotEmpty) {
      return partial.value;
    }

    return SectionCatalogEntry(
      title: rawTitle,
      subtitle: 'Working on this area',
      icon: Icons.autorenew_outlined,
    );
  }
}

/// Tracks clean/optimize progress from streamed CLI output.
class CliActivityParser {
  CliActivityParser({Map<String, SectionCatalogEntry>? sectionCatalog})
      : _sectionCatalog = sectionCatalog ?? const {};

  final Map<String, SectionCatalogEntry> _sectionCatalog;

  final List<ActivitySection> _sections = [];
  String? _currentActivityLabel;
  int? _activeSectionIndex;

  List<ActivitySection> get sections => List.unmodifiable(_sections);
  String? get currentActivityLabel => _currentActivityLabel;

  double get progress {
    if (_sections.isEmpty) return 0;

    var total = 0.0;
    for (final section in _sections) {
      total += switch (section.status) {
        ActivitySectionStatus.completed => 1,
        ActivitySectionStatus.skipped => 1,
        ActivitySectionStatus.active => _sectionPartial(section),
        ActivitySectionStatus.pending => 0,
      };
    }
    return (total / _sections.length).clamp(0.0, 1.0);
  }

  void reset() {
    _sections.clear();
    _currentActivityLabel = null;
    _activeSectionIndex = null;
  }

  void finish() {
    if (_activeSectionIndex != null) {
      _completeSectionAt(_activeSectionIndex!);
    }
    for (var i = 0; i < _sections.length; i++) {
      if (_sections[i].status == ActivitySectionStatus.active) {
        _completeSectionAt(i);
      }
    }
  }

  void handleLine(String rawLine) {
    final line = MoleCliPassword.stripAnsi(rawLine);
    final trimmed = line.trim();
    if (trimmed.isEmpty || _shouldIgnoreLine(trimmed)) return;

    final isIndented = line.startsWith('  ') || line.startsWith('\t');

    if (!isIndented) {
      final sectionTitle = _parseSectionTitle(trimmed);
      if (sectionTitle != null) {
        _startSection(sectionTitle);
        return;
      }
    }

    if (isIndented && RegExp(r'^\s+>\s+').hasMatch(line)) {
      final dryRun = trimmed.replaceFirst(RegExp(r'^>\s*'), '').trim();
      if (dryRun.isNotEmpty) {
        _addCompletedItem('Preview: $dryRun');
      }
      return;
    }

    final successLabel = _parseSuccessLabel(trimmed);
    if (successLabel != null) {
      _addCompletedItem(successLabel);
      return;
    }

    if (_isSkippedSectionLine(trimmed)) {
      _completeCurrentSection(skipped: true);
      return;
    }

    final warningLabel = _parseWarningLabel(trimmed);
    if (warningLabel != null) {
      _addWarningItem(warningLabel);
      return;
    }

    final spinnerLabel = _parseSpinnerLabel(trimmed);
    if (spinnerLabel != null) {
      _setActiveActivity(spinnerLabel);
    } else if (isIndented && _looksLikeStatusLine(trimmed)) {
      _setActiveActivity(trimmed);
    }
  }

  double _sectionPartial(ActivitySection section) {
    final itemCount = section.items.length;
    if (itemCount == 0) return 0.35;
    final completed = section.completedItemCount;
    return (0.2 + (completed / itemCount) * 0.75).clamp(0.2, 0.95);
  }

  bool _shouldIgnoreLine(String line) {
    if (line.startsWith('===')) return true;
    if (line.contains('Cleanup complete')) return true;
    if (line.contains('Optimization Complete')) return true;
    if (line.contains('Optimize complete')) return true;
    if (line.contains('Dry Run Complete')) return true;
    if (line.contains('Space freed:')) return true;
    if (line.contains('Free space now:')) return true;
    if (line.contains('System fully optimized')) return true;
    if (line.contains('Applied ') && line.contains('optimizations')) {
      return true;
    }
    if (line.contains('Would apply') && line.contains('optimizations')) {
      return true;
    }
    if (line.contains('Active Whitelist:')) return true;
    if (line.contains('Admin required')) return true;
    if (line.contains('admin access')) return true;
    if (line.contains('Password:')) return true;
    if (RegExp(r'^Optimize$').hasMatch(line)) return true;
    if (RegExp(r'^Clean$').hasMatch(line)) return true;
    if (line.contains('Optimize and Maintain')) return true;
    if (line.contains('DRY RUN MODE')) return true;
    if (line.contains('Free space on')) return true;
    if (line.contains('Optimizations applied:')) return true;
    if (line.contains('Repairs applied:')) return true;
    if (line.contains('Issues fixed:')) return true;
    if (line.contains('Issues found:')) return true;
    if (line.contains('System health:')) return true;
    if (line.startsWith('System  ')) return true;
    if (line.contains('Run System File Checker')) return true;
    if (line.contains('Requires administrator')) return true;
    return false;
  }

  bool _looksLikeStatusLine(String line) {
    return line.startsWith('Running ') ||
        line.contains('...') ||
        RegExp(r'^(Checking|Scanning|Clearing|Repairing)\b').hasMatch(line);
  }

  String? _parseSectionTitle(String line) {
    final match = RegExp(r'^[➤>]\s+(.+)$').firstMatch(line);
    return match?.group(1)?.trim();
  }

  String? _parseSuccessLabel(String line) {
    final match = RegExp(r'^[✓+*]\s+(.+)$').firstMatch(line);
    final label = match?.group(1)?.trim();
    if (label == null || label.isEmpty) return null;
    return _humanizeActivity(label);
  }

  String? _parseWarningLabel(String line) {
    if (line.contains('Whitelist:')) {
      return line.replaceFirst(RegExp(r'^.*Whitelist:\s*'), 'Whitelist: ').trim();
    }
    final match = RegExp(r'^[!⚠]\s+(.+)$').firstMatch(line);
    return match?.group(1)?.trim();
  }

  String? _parseSpinnerLabel(String line) {
    final match = RegExp(r'^[|/\\-]\s+(.+)$').firstMatch(line);
    final label = match?.group(1)?.trim();
    if (label == null || label.isEmpty) return null;
    if (label.endsWith('...')) {
      return label.substring(0, label.length - 3).trim();
    }
    return label;
  }

  bool _isSkippedSectionLine(String line) {
    return line.contains('Nothing to clean') ||
        line.contains('Nothing to tidy') ||
        line.contains('System is already clean');
  }

  void _startSection(String rawTitle) {
    final entry = CliSectionCatalog.resolve(
      rawTitle,
      catalog: _sectionCatalog,
    );

    if (_activeSectionIndex != null) {
      _completeSectionAt(_activeSectionIndex!);
    }

    final existingIndex = _sections.indexWhere((section) => section.id == rawTitle);
    if (existingIndex >= 0) {
      _activeSectionIndex = existingIndex;
      _sections[existingIndex] = _sections[existingIndex].copyWith(
        status: ActivitySectionStatus.active,
        clearCurrentActivity: true,
      );
      _currentActivityLabel = entry.subtitle;
      return;
    }

    _sections.add(
      ActivitySection(
        id: rawTitle,
        title: entry.title,
        subtitle: entry.subtitle,
        icon: entry.icon,
        status: ActivitySectionStatus.active,
        items: const [],
        currentActivity: entry.subtitle,
      ),
    );
    _activeSectionIndex = _sections.length - 1;
    _currentActivityLabel = entry.subtitle;
  }

  void _setActiveActivity(String label) {
    if (_activeSectionIndex == null) {
      _startSection('Working');
    }
    final index = _activeSectionIndex!;
    final section = _sections[index];
    final trimmed = _humanizeActivity(label);

    final items = List<ActivityItem>.from(section.items);
    final activeIndex = items.indexWhere(
      (item) => item.status == ActivityItemStatus.active,
    );
    if (activeIndex >= 0) {
      items[activeIndex] = ActivityItem(
        label: trimmed,
        status: ActivityItemStatus.active,
      );
    } else {
      items.add(ActivityItem(label: trimmed, status: ActivityItemStatus.active));
    }

    _sections[index] = section.copyWith(
      items: items,
      currentActivity: trimmed,
    );
    _currentActivityLabel = trimmed;
  }

  void _addCompletedItem(String label) {
    if (_activeSectionIndex == null) {
      _startSection('Working');
    }

    final index = _activeSectionIndex!;
    final section = _sections[index];
    final trimmed = _humanizeActivity(label);
    final items = List<ActivityItem>.from(section.items);

    final activeIndex = items.indexWhere(
      (item) => item.status == ActivityItemStatus.active,
    );
    if (activeIndex >= 0) {
      items[activeIndex] = ActivityItem(
        label: trimmed,
        status: ActivityItemStatus.completed,
      );
    } else {
      items.add(
        ActivityItem(label: trimmed, status: ActivityItemStatus.completed),
      );
    }

    if (_isSkippedSectionLine(trimmed)) {
      _sections[index] = section.copyWith(
        items: items,
        status: ActivitySectionStatus.skipped,
        clearCurrentActivity: true,
      );
      return;
    }

    _sections[index] = section.copyWith(
      items: items,
      clearCurrentActivity: true,
    );
    _currentActivityLabel = trimmed;
  }

  void _addWarningItem(String label) {
    if (_activeSectionIndex == null) {
      _startSection('Working');
    }

    final index = _activeSectionIndex!;
    final section = _sections[index];
    final items = List<ActivityItem>.from(section.items)
      ..add(ActivityItem(label: label, status: ActivityItemStatus.warning));

    _sections[index] = section.copyWith(
      items: items,
      currentActivity: label,
    );
    _currentActivityLabel = label;
  }

  void _completeCurrentSection({bool skipped = false}) {
    if (_activeSectionIndex == null) return;
    _completeSectionAt(_activeSectionIndex!, skipped: skipped);
  }

  void _completeSectionAt(int index, {bool skipped = false}) {
    final section = _sections[index];
    final items = section.items
        .map(
          (item) => item.status == ActivityItemStatus.active
              ? ActivityItem(
                  label: item.label,
                  status: ActivityItemStatus.completed,
                )
              : item,
        )
        .toList();

    _sections[index] = section.copyWith(
      status: skipped ? ActivitySectionStatus.skipped : ActivitySectionStatus.completed,
      items: items,
      clearCurrentActivity: true,
    );

    if (_activeSectionIndex == index) {
      _activeSectionIndex = null;
      _currentActivityLabel = null;
    }
  }

  String _humanizeActivity(String label) {
    var text = label.trim();
    if (text.startsWith('Cleaning ')) {
      text = text.substring('Cleaning '.length);
    } else if (text.startsWith('Scanning ')) {
      text = text.substring('Scanning '.length);
    }
    if (text.endsWith('...')) {
      text = text.substring(0, text.length - 3).trim();
    }
    return text.isEmpty ? label.trim() : text;
  }
}
