import 'package:flutter/material.dart';

import '../../design/motion.dart';
import '../../design/palette.dart';
import '../../design/tokens.dart';
import 'navigator_panel.dart';

/// The far-left workspace rail: brand, destination switcher and global actions.
class WorkspaceRail extends StatelessWidget {
  const WorkspaceRail({
    super.key,
    required this.destination,
    required this.onDestinationChanged,
    required this.navigatorOpen,
    required this.onToggleNavigator,
    required this.sessionCount,
    required this.onNewServer,
    required this.onOpenPalette,
    required this.onOpenSettings,
  });

  final NavigatorDestination destination;
  final ValueChanged<NavigatorDestination> onDestinationChanged;
  final bool navigatorOpen;
  final VoidCallback onToggleNavigator;
  final int sessionCount;
  final VoidCallback onNewServer;
  final VoidCallback onOpenPalette;
  final VoidCallback onOpenSettings;

  static const double width = 56;
  static const double _firstSlotTop = 76;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(right: BorderSide(color: p.border)),
      ),
      child: Column(
        children: [
          const SizedBox(height: Space.x3),
          Tooltip(
            message: 'Termora',
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: p.accentSoft,
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Icon(Icons.terminal_rounded, size: 18, color: p.accent),
            ),
          ),
          const SizedBox(height: Space.x2),
          _RailIndicator(
            index: destination.index,
            firstSlotTop: _firstSlotTop,
          ),
          _DestinationButton(
            icon: Icons.dns_outlined,
            tooltip: '服务器',
            selected: destination == NavigatorDestination.servers,
            onTap: () => onDestinationChanged(NavigatorDestination.servers),
          ),
          _DestinationButton(
            icon: Icons.terminal,
            tooltip: '会话',
            selected: destination == NavigatorDestination.sessions,
            onTap: () => onDestinationChanged(NavigatorDestination.sessions),
            badge: sessionCount,
          ),
          const Spacer(),
          _RailIcon(icon: Icons.add, tooltip: '新增服务器', onTap: onNewServer),
          _RailIcon(
            icon: Icons.search,
            tooltip: '命令面板 (Ctrl+K)',
            onTap: onOpenPalette,
          ),
          _RailIcon(
            icon: Icons.settings_outlined,
            tooltip: '设置',
            onTap: onOpenSettings,
          ),
          const SizedBox(height: Space.x2),
          Divider(height: 1, color: p.border),
          const SizedBox(height: Space.x1),
          IconButton(
            tooltip: navigatorOpen ? '折叠侧栏' : '展开侧栏',
            onPressed: onToggleNavigator,
            icon: AnimatedRotation(
              turns: navigatorOpen ? 0 : 0.5,
              duration: Motion.panel,
              curve: Motion.emphasized,
              child: const Icon(Icons.chevron_left, size: 18),
            ),
          ),
          const SizedBox(height: Space.x2),
        ],
      ),
    );
  }
}

class _DestinationButton extends StatelessWidget {
  const _DestinationButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        height: 44,
        child: Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: AnimatedContainer(
              duration: AppMotion.scale(context, Motion.control),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected ? p.accentSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Icon(
                      icon,
                      size: 20,
                      color: selected ? p.accent : p.textSecondary,
                    ),
                  ),
                  if (badge > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: _Badge(count: badge),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return AnimatedSwitcher(
      duration: Motion.control,
      child: Container(
        key: ValueKey(count),
        width: 16,
        height: 16,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
        child: Text(
          count > 9 ? '9+' : '$count',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: p.onAccent,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class _RailIcon extends StatelessWidget {
  const _RailIcon({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 20),
    );
  }
}

class _RailIndicator extends StatefulWidget {
  const _RailIndicator({required this.index, required this.firstSlotTop});

  final int index;
  final double firstSlotTop;

  @override
  State<_RailIndicator> createState() => _RailIndicatorState();
}

class _RailIndicatorState extends State<_RailIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pos = AnimationController(
    vsync: this,
    duration: Motion.spatial,
    value: widget.index.toDouble(),
  );

  @override
  void didUpdateWidget(_RailIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      if (AppMotion.reduced(context)) {
        _pos.value = widget.index.toDouble();
      } else {
        _pos.animateWith(
          Motion.to(
            Motion.snap,
            from: _pos.value,
            to: widget.index.toDouble(),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return AnimatedBuilder(
      animation: _pos,
      builder: (context, _) => Transform.translate(
        offset: Offset(0, widget.firstSlotTop + 44 * _pos.value),
        child: SizedBox(
          width: WorkspaceRail.width,
          height: 20,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 3,
              height: 20,
              decoration: BoxDecoration(
                color: p.accent,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(2),
                  bottomRight: Radius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
