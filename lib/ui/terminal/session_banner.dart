import 'package:flutter/material.dart';

import '../../design/palette.dart';
import '../../design/tokens.dart';
import '../../design/widgets/link_indicator.dart';
import '../../session/terminal_session.dart';

/// A 40px banner shown over the terminal when a session is failed or
/// disconnected, offering a reconnect action. Shared by the mobile terminal
/// page and the desktop stage.
class SessionBanner extends StatelessWidget {
  const SessionBanner({super.key, required this.session});

  final TerminalSession session;

  Future<void> _reconnect() {
    return session.reconnect(
      width: session.terminal.viewWidth > 0 ? session.terminal.viewWidth : 80,
      height: session.terminal.viewHeight > 0 ? session.terminal.viewHeight : 24,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: Space.x3),
      color: p.dangerSoft,
      child: Row(
        children: [
          LinkIndicator(
            status: session.status,
            size: 9,
            emphasis: LinkEmphasis.standalone,
          ),
          const SizedBox(width: Space.x2),
          Expanded(
            child: Text(
              session.errorMessage ?? '连接已断开',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: p.textPrimary),
            ),
          ),
          TextButton(
            onPressed: _reconnect,
            child: const Text('重新连接'),
          ),
        ],
      ),
    );
  }
}
