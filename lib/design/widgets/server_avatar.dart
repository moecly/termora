import 'package:flutter/material.dart';

import '../../session/session_status.dart';
import '../motion.dart';
import '../palette.dart';
import 'link_indicator.dart';

const List<Color> _palette = [
  Color(0xFF4FD1FF),
  Color(0xFF3ED598),
  Color(0xFFF0B429),
  Color(0xFFFF5A5F),
  Color(0xFF9D7BFF),
  Color(0xFFF07AA8),
  Color(0xFF56B6C2),
  Color(0xFF7FA0FF),
];

/// Shared hero tag for a server's avatar (list → terminal page).
String serverHeroTag(String id) => 'server-avatar-$id';

/// Hero tag for an active-session card's avatar (session list → terminal page).
/// Distinct from [serverHeroTag] so the flight starts from the tapped card
/// rather than from the same server's row in the server list.
String sessionHeroTag(String id) => 'session-avatar-$id';

/// A rounded square avatar showing the first character of [seed], colored
/// deterministically from the seed.
class ServerAvatar extends StatelessWidget {
  const ServerAvatar({
    super.key,
    required this.seed,
    this.size = 40,
    this.heroTag,
    this.status,
  });

  final String seed;
  final double size;

  /// When set, wraps the avatar in a [Hero] for a shared-element transition.
  final String? heroTag;

  /// When set, draws a status-colored outline along the bottom edge.
  final SessionStatus? status;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final color = _palette[seed.hashCode.abs() % _palette.length];
    final initial = seed.isEmpty ? '?' : seed.characters.first.toUpperCase();
    final radius = BorderRadius.circular(size * 0.30);
    final avatar = AnimatedContainer(
      duration: Motion.control,
      curve: Motion.easeInOut,
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, p.bg, 0.25)!, color],
        ),
        borderRadius: radius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.35,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
    Widget result = avatar;
    final s = status;
    if (s != null) {
      result = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.30 + 2),
          border: Border.all(color: linkStatusColor(p, s), width: 2),
        ),
        child: result,
      );
    }
    final tag = heroTag;
    return tag == null ? result : Hero(tag: tag, child: result);
  }
}
