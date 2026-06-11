import 'package:flutter/material.dart';

enum ActivitySectionStatus { pending, active, completed, skipped }

enum ActivityItemStatus { active, completed, warning, skipped }

class ActivityItem {
  const ActivityItem({
    required this.label,
    required this.status,
  });

  final String label;
  final ActivityItemStatus status;
}

class ActivitySection {
  const ActivitySection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.status,
    required this.items,
    this.currentActivity,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final ActivitySectionStatus status;
  final List<ActivityItem> items;
  final String? currentActivity;

  int get completedItemCount =>
      items.where((item) => item.status == ActivityItemStatus.completed).length;

  String? get statusSummary {
    return switch (status) {
      ActivitySectionStatus.skipped => 'Already clean',
      ActivitySectionStatus.completed when items.isEmpty => 'Already clean',
      ActivitySectionStatus.completed when completedItemCount > 0 =>
        '$completedItemCount cleaned',
      ActivitySectionStatus.completed => 'Done',
      ActivitySectionStatus.active => currentActivity,
      ActivitySectionStatus.pending => null,
    };
  }

  ActivitySection copyWith({
    String? id,
    String? title,
    String? subtitle,
    IconData? icon,
    ActivitySectionStatus? status,
    List<ActivityItem>? items,
    String? currentActivity,
    bool clearCurrentActivity = false,
  }) {
    return ActivitySection(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      status: status ?? this.status,
      items: items ?? this.items,
      currentActivity:
          clearCurrentActivity ? null : (currentActivity ?? this.currentActivity),
    );
  }
}
