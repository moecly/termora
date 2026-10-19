import 'package:flutter/material.dart';

import '../../app/app.dart';
import '../../design/motion.dart';
import '../../design/palette.dart';
import '../../design/tokens.dart';
import '../../design/widgets/link_indicator.dart';
import '../../design/widgets/link_pulse.dart';
import '../../design/widgets/pressable.dart';
import '../../design/widgets/scroll.dart';
import '../../design/widgets/server_avatar.dart';
import '../../session/session_status.dart';
import '../../session/terminal_session.dart';

/// The horizontal session tab strip shown at the top of the stage.
class SessionStrip extends StatelessWidget {
  const SessionStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = ServicesScope.of(context);
    return ListenableBuilder(
      listenable: scope.manager,
      builder: (context, _) {
        final manager = scope.manager;
        final connecting =
            manager.sessions.any((s) => s.status == SessionStatus.connecting);
        return Column(
          children: [
            Expanded(
              child: ScrollConfiguration(
                behavior: const HorizontalDragScrollBehavior(),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final session in manager.sessions)
                        _SessionTab(
                          session: session,
                          active: session.id == manager.activeSessionId,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            LinkPulse(active: connecting, height: 1),
          ],
        );
      },
    );
  }
}

class _SessionTab extends StatelessWidget {
  const _SessionTab({required this.session, required this.active});

  final TerminalSession session;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final manager = ServicesScope.of(context).manager;
    final p = AppPalette.of(context);
    return HoverSurface(
      baseColor: Colors.transparent,
      hoverColor: p.hoverOverlay,
      borderRadius: BorderRadius.zero,
      border: const BorderSide(color: Colors.transparent),
      hoverBorder: const BorderSide(color: Colors.transparent),
      onTap: () => manager.activate(session.id),
      child: AnimatedContainer(
        duration: Motion.tab,
        curve: Motion.emphasized,
        padding: const EdgeInsets.symmetric(horizontal: Space.x3),
        decoration: BoxDecoration(
          color: active ? p.surfaceHighest : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              width: 2,
              color: active ? p.accent : Colors.transparent,
            ),
          ),
        ),
        child: Row(
          children: [
            ServerAvatar(seed: session.server.name, size: 18, status: session.status),
            const SizedBox(width: Space.x2),
            Text(
              session.server.name,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: Space.x2),
            LinkIndicator(status: session.status, size: 6),
            const SizedBox(width: Space.x1),
            Pressable(
              onTap: () => manager.closeSession(session.id),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.close, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
