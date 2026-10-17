import 'package:flutter/material.dart';

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

/// A rounded square avatar showing the first character of [seed], colored
/// deterministically from the seed.
class ServerAvatar extends StatelessWidget {
  const ServerAvatar({super.key, required this.seed, this.size = 40});

  final String seed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = _palette[seed.hashCode.abs() % _palette.length];
    final initial = seed.isEmpty ? '?' : seed.characters.first.toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(Radii.md),
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
  }
}
