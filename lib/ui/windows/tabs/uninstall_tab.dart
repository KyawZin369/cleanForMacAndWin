import 'package:flutter/material.dart';
import 'package:mole_ui/core/logic/uninstall_controller.dart';
import 'package:mole_ui/core/models/uninstall_app.dart';
import 'package:mole_ui/ui/windows/widgets/fluent_widgets.dart';

class WindowsUninstallTab extends StatefulWidget {
  const WindowsUninstallTab({super.key, required this.controller});

  final UninstallController controller;

  @override
  State<WindowsUninstallTab> createState() => _WindowsUninstallTabState();
}

class _WindowsUninstallTabState extends State<WindowsUninstallTab> {
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select apps to remove',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF323130),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${controller.selectedCount}/${controller.apps.length} selected',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF605E5C),
                            ),
                          ),
                        ],
                      ),
                    ),
                    WindowsSecondaryButton(
                      label: 'Refresh',
                      onPressed:
                          controller.isLoading ? null : controller.loadApps,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search apps',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2),
                    borderSide: const BorderSide(color: Color(0xFF8A8886)),
                  ),
                ),
                onChanged: controller.setSearchQuery,
              ),
              const SizedBox(height: 12),
              Expanded(child: _AppList(controller: controller)),
              const SizedBox(height: 12),
              Row(
                children: [
                  WindowsSecondaryButton(
                    label: 'Select all',
                    onPressed: controller.apps.isEmpty
                        ? null
                        : controller.selectAllVisible,
                  ),
                  const SizedBox(width: 8),
                  WindowsSecondaryButton(
                    label: 'Clear',
                    onPressed: controller.selectedCount == 0
                        ? null
                        : controller.clearSelection,
                  ),
                  const Spacer(),
                  WindowsPrimaryButton(
                    label: controller.isUninstalling
                        ? 'Removing...'
                        : 'Uninstall selected',
                    onPressed: controller.isUninstalling ||
                            controller.selectedCount == 0
                        ? null
                        : controller.uninstallSelected,
                  ),
                ],
              ),
              if (controller.errorMessage != null) ...[
                const SizedBox(height: 12),
                WindowsMessageBanner.error(message: controller.errorMessage!),
              ],
              if (controller.resultMessage != null) ...[
                const SizedBox(height: 12),
                WindowsMessageBanner.success(message: controller.resultMessage!),
              ],
            ],
          ),
        );
      },
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

    if (controller.visibleApps.isEmpty) {
      return const Center(
        child: Text(
          'No apps found',
          style: TextStyle(color: Color(0xFF605E5C)),
        ),
      );
    }

    return WindowsCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        itemCount: controller.visibleApps.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEDEBE9)),
        itemBuilder: (context, index) {
          final app = controller.visibleApps[index];
          return _AppRow(app: app, controller: controller);
        },
      ),
    );
  }
}

class _AppRow extends StatelessWidget {
  const _AppRow({required this.app, required this.controller});

  final UninstallApp app;
  final UninstallController controller;

  @override
  Widget build(BuildContext context) {
    final selected = controller.isSelected(app);

    return Material(
      color: selected ? const Color(0xFFF3F9FD) : Colors.transparent,
      child: InkWell(
        onTap: () => controller.toggleSelection(app),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Checkbox(
                value: selected,
                activeColor: const Color(0xFF0078D4),
                onChanged: (_) => controller.toggleSelection(app),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF323130),
                      ),
                    ),
                    if (app.source.isNotEmpty)
                      Text(
                        app.source,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF605E5C),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                app.size.isNotEmpty ? app.size : '—',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF605E5C),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
