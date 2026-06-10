import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mole_ui/core/logic/uninstall_controller.dart';
import 'package:mole_ui/core/models/uninstall_app.dart';
import 'package:mole_ui/ui/mac/widgets/glass_action_widgets.dart';
import 'package:mole_ui/ui/mac/widgets/password_prompt_listener.dart';

class UninstallTab extends StatefulWidget {
  const UninstallTab({super.key, required this.controller});

  final UninstallController controller;

  @override
  State<UninstallTab> createState() => _UninstallTabState();
}

class _UninstallTabState extends State<UninstallTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.apps.isEmpty && !widget.controller.isLoading) {
        widget.controller.loadApps();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PasswordPromptListener(
      listenable: widget.controller,
      readPrompt: () => widget.controller.passwordPrompt,
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;

          return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(controller: controller),
              const SizedBox(height: 16),
              _Toolbar(controller: controller),
              const SizedBox(height: 12),
              Expanded(child: _AppList(controller: controller)),
              const SizedBox(height: 16),
              _Footer(controller: controller),
            ],
          ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final UninstallController controller;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Apps to Remove',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.4,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${controller.selectedCount}/${controller.apps.length} selected',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF1C1C1E).withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (controller.isLoading || controller.isUninstalling)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.controller});

  final UninstallController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GlassSearchField(
            value: controller.searchQuery,
            onChanged: controller.setSearchQuery,
            enabled: !controller.isUninstalling,
          ),
        ),
        const SizedBox(width: 10),
        _GlassIconButton(
          tooltip: 'Select all visible',
          icon: Icons.done_all_rounded,
          onPressed: controller.isUninstalling ? null : controller.selectAllVisible,
        ),
        const SizedBox(width: 6),
        _GlassIconButton(
          tooltip: 'Clear selection',
          icon: Icons.clear_all_rounded,
          onPressed: controller.isUninstalling ? null : controller.clearSelection,
        ),
        const SizedBox(width: 6),
        _SortButton(controller: controller),
        const SizedBox(width: 6),
        _GlassIconButton(
          tooltip: 'Refresh',
          icon: Icons.refresh_rounded,
          onPressed: controller.isUninstalling ? null : controller.loadApps,
        ),
      ],
    );
  }
}

class _GlassSearchField extends StatelessWidget {
  const _GlassSearchField({
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: TextField(
          enabled: enabled,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Search apps...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.55),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.65)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.65)),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.controller});

  final UninstallController controller;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Sort',
      child: PopupMenuButton<UninstallSort>(
        enabled: !controller.isUninstalling,
        tooltip: '',
        onSelected: controller.setSort,
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: UninstallSort.nameAsc,
            child: Text('Name A-Z'),
          ),
          PopupMenuItem(
            value: UninstallSort.nameDesc,
            child: Text('Name Z-A'),
          ),
          PopupMenuItem(
            value: UninstallSort.sizeDesc,
            child: Text('Size largest'),
          ),
          PopupMenuItem(
            value: UninstallSort.sizeAsc,
            child: Text('Size smallest'),
          ),
          PopupMenuItem(
            value: UninstallSort.sourceAsc,
            child: Text('Source'),
          ),
        ],
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              width: 42,
              height: 42,
              color: Colors.white.withValues(alpha: 0.55),
              child: Icon(
                Icons.sort_rounded,
                size: 20,
                color: controller.isUninstalling
                    ? const Color(0xFF1C1C1E).withValues(alpha: 0.25)
                    : const Color(0xFF007AFF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Material(
            color: Colors.white.withValues(alpha: 0.55),
            child: InkWell(
              onTap: onPressed,
              child: SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  icon,
                  size: 20,
                  color: onPressed == null
                      ? const Color(0xFF1C1C1E).withValues(alpha: 0.25)
                      : const Color(0xFF007AFF),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppList extends StatelessWidget {
  const _AppList({required this.controller});

  final UninstallController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading && controller.apps.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage != null && controller.apps.isEmpty) {
      return _MessagePanel(
        icon: Icons.error_outline_rounded,
        message: controller.errorMessage!,
        actionLabel: 'Retry',
        onAction: controller.loadApps,
      );
    }

    final apps = controller.visibleApps;
    if (apps.isEmpty) {
      return _MessagePanel(
        icon: Icons.apps_rounded,
        message: controller.searchQuery.isEmpty
            ? 'No apps found.'
            : 'No apps match your search.',
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
          ),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: apps.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: Colors.black.withValues(alpha: 0.05),
            ),
            itemBuilder: (context, index) {
              final app = apps[index];
              return _AppListTile(
                app: app,
                selected: controller.isSelected(app),
                enabled: !controller.isUninstalling,
                onToggle: () => controller.toggleSelection(app),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AppListTile extends StatelessWidget {
  const _AppListTile({
    required this.app,
    required this.selected,
    required this.enabled,
    required this.onToggle,
  });

  final UninstallApp app;
  final bool selected;
  final bool enabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(0xFF007AFF).withValues(alpha: 0.08)
          : Colors.transparent,
      child: InkWell(
        onTap: enabled ? onToggle : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? const Color(0xFF007AFF)
                    : const Color(0xFF1C1C1E).withValues(alpha: 0.25),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${app.source} | ${app.size}',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF1C1C1E).withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.controller});

  final UninstallController controller;

  Future<void> _confirmUninstall(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uninstall selected apps?'),
        content: Text(
          '${controller.selectedCount} app(s) will be moved to Trash.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Uninstall'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await controller.uninstallSelected();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (controller.statusMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              controller.statusMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: const Color(0xFF1C1C1E).withValues(alpha: 0.55),
              ),
            ),
          ),
        if (controller.resultMessage != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassActionSuccessText(message: controller.resultMessage!),
          ),
        ],
        if (controller.errorMessage != null && controller.apps.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              controller.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: const Color(0xFFFF3B30).withValues(alpha: 0.85),
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: controller.selectedCount == 0 || controller.isUninstalling
                  ? [
                      const Color(0xFFB0B0B5),
                      const Color(0xFF9E9EA3),
                    ]
                  : const [
                      Color(0xFF5AC8FA),
                      Color(0xFF007AFF),
                      Color(0xFF5856D6),
                    ],
            ),
            boxShadow: controller.selectedCount == 0
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF007AFF).withValues(alpha: 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: controller.selectedCount == 0 || controller.isUninstalling
                  ? null
                  : () => _confirmUninstall(context),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  controller.isUninstalling
                      ? 'Uninstalling...'
                      : 'Uninstall Selected (${controller.selectedCount})',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 42, color: Colors.black.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF1C1C1E).withValues(alpha: 0.55),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
