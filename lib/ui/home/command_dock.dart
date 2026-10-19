import 'package:flutter/material.dart';

import '../../design/motion.dart';
import '../../design/palette.dart';
import '../../design/tokens.dart';

/// A single action shown in the expanded [CommandDock].
class DockAction {
  const DockAction({
    required this.id,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String id;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// A bottom command dock: a filled primary capsule that expands into a stack of
/// secondary actions over a full-height scrim.
class CommandDock extends StatefulWidget {
  const CommandDock({
    super.key,
    required this.primary,
    required this.actions,
  });

  final DockAction primary;
  final List<DockAction> actions;

  @override
  State<CommandDock> createState() => _CommandDockState();
}

class _CommandDockState extends State<CommandDock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.panel + Motion.stagger * widget.actions.length,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _setOpen(bool open) {
    if (AppMotion.reduced(context)) {
      _c.value = open ? 1 : 0;
      return;
    }
    if (open) {
      _c.forward();
    } else {
      _c.reverse();
    }
  }

  void _toggle() => _setOpen(_c.value <= 0.5);

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final open = _c.value > 0.001;
        return Stack(
          children: [
            if (open)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _setOpen(false),
                  child: AnimatedOpacity(
                    opacity: _c.value,
                    duration: AppMotion.scale(context, Motion.hover),
                    child: ColoredBox(color: p.scrim),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.x4,
                    0,
                    Space.x4,
                    Space.x4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (open)
                        for (var i = widget.actions.length - 1; i >= 0; i--)
                          _buildAction(widget.actions[i], i),
                      if (open) const SizedBox(height: Space.x2),
                      _buildCapsule(p),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAction(DockAction action, int index) {
    final total = _c.duration!.inMilliseconds;
    final startMs = (Motion.stagger * index).inMilliseconds;
    final revealMs = Motion.panel.inMilliseconds;
    final start = (startMs / total).clamp(0.0, 1.0);
    final end = ((startMs + revealMs) / total).clamp(0.0, 1.0);
    final curved = CurvedAnimation(
      parent: _c,
      curve: Interval(start, end == start ? 1.0 : end, curve: Motion.emphasized),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final t = curved.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - t)),
            child: Transform.scale(scale: 0.9 + 0.1 * t, child: child),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: Space.x2),
        child: _ActionPill(action: action, onTap: () {
          _setOpen(false);
          action.onTap();
        }),
      ),
    );
  }

  Widget _buildCapsule(AppPalette p) {
    return Material(
      color: p.accent,
      borderRadius: BorderRadius.circular(Radii.pill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          widget.primary.onTap();
          _setOpen(false);
        },
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: Space.x5),
              Icon(widget.primary.icon, size: 20, color: p.onAccent),
              const SizedBox(width: Space.x2),
              Text(
                widget.primary.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: p.onAccent,
                ),
              ),
              const SizedBox(width: Space.x4),
              Container(
                width: 1,
                height: 24,
                color: p.onAccent.withValues(alpha: 0.25),
              ),
              const SizedBox(width: Space.x1),
              Tooltip(
                message: '更多操作',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggle,
                  child: SizedBox(
                    width: 40,
                    height: 52,
                    child: Center(
                      child: AnimatedRotation(
                        turns: _c.value * 0.5,
                        duration: AppMotion.scale(context, Motion.panel),
                        child: Icon(
                          Icons.keyboard_arrow_up,
                          size: 22,
                          color: p.onAccent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Space.x1),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.action, required this.onTap});

  final DockAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Material(
      color: p.surfaceHigh,
      borderRadius: BorderRadius.circular(Radii.pill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: Space.x4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(color: p.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(action.icon, size: 18, color: p.accent),
              const SizedBox(width: Space.x2),
              Text(
                action.label,
                style: TextStyle(fontSize: 14, color: p.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
