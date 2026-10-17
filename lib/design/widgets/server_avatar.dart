import 'package:flutter/material.dart';

import '../motion.dart';
import '../tokens.dart';

const List<Color> _palette = [
  Color(0xFF5E6AD2),
  Color(0xFF4CB782),
  Color(0xFFE2A83B),
  Color(0xFFE5484D),
  Color(0xFF56B6C2),
  Color(0xFFC678DD),
  Color(0xFF3E9BD8),
  Color(0xFFB58900),
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
  });

  final String seed;
  final double size;

  /// When set, wraps the avatar in a [Hero] for a shared-element transition.
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final color = _palette[seed.hashCode.abs() % _palette.length];
    final initial = seed.isEmpty ? '?' : seed.characters.first.toUpperCase();
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
          colors: [Color.lerp(color, Colors.white, 0.18)!, color],
        ),
        borderRadius: BorderRadius.circular(Radii.md),
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
    final tag = heroTag;
    return tag == null ? avatar : Hero(tag: tag, child: avatar);
  }
}
