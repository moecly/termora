import 'package:flutter/material.dart';

import '../motion.dart';

/// A list that animates insertions, removals and shifts between rebuilds.
///
/// Callers supply a stable, unique list of [keys]; whenever the keys change
/// this widget diffs them against its internal mirror and drives an
/// [AnimatedList]/[SliverAnimatedList]. Set [sliver] to embed it inside a
/// [CustomScrollView]. Both the incoming and outgoing transitions use the same
/// fade + vertical size animation.
class AnimatedDiffList extends StatefulWidget {
  const AnimatedDiffList({
    super.key,
    required this.keys,
    required this.itemBuilder,
    required this.removedBuilder,
    this.sliver = false,
    this.padding,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
    this.duration = Motion.panel,
  });

  final List<String> keys;

  /// Builds a visible row. The [animation] is the insertion animation
  /// (complete for initial rows).
  final Widget Function(
    BuildContext context,
    int index,
    String key,
    Animation<double> animation,
  )
  itemBuilder;

  /// Builds an outgoing row during its removal animation. Must render using
  /// data retained by the caller for [key].
  final Widget Function(
    BuildContext context,
    String key,
    Animation<double> animation,
  )
  removedBuilder;

  final bool sliver;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Duration duration;

  @override
  State<AnimatedDiffList> createState() => _AnimatedDiffListState();
}

class _AnimatedDiffListState extends State<AnimatedDiffList> {
  final GlobalKey<SliverAnimatedListState> _sliverKey =
      GlobalKey<SliverAnimatedListState>();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  late List<String> _keys;

  @override
  void initState() {
    super.initState();
    assert(
      widget.keys.length == widget.keys.toSet().length,
      'AnimatedDiffList keys must be unique',
    );
    _keys = List<String>.of(widget.keys);
  }

  @override
  void didUpdateWidget(AnimatedDiffList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_listEquals(widget.keys, oldWidget.keys)) {
      _apply(widget.keys);
    }
  }

  void _insert(int index, Duration duration) {
    if (widget.sliver) {
      _sliverKey.currentState?.insertItem(index, duration: duration);
    } else {
      _listKey.currentState?.insertItem(index, duration: duration);
    }
  }

  void _remove(
    int index,
    Widget Function(BuildContext context, Animation<double> animation) builder,
    Duration duration,
  ) {
    if (widget.sliver) {
      _sliverKey.currentState?.removeItem(index, builder, duration: duration);
    } else {
      _listKey.currentState?.removeItem(index, builder, duration: duration);
    }
  }

  void _apply(List<String> next) {
    final duration = AppMotion.scale(context, widget.duration);
    final nextSet = next.toSet();

    // 1) Remove keys that are gone (reverse order keeps indices valid).
    for (var i = _keys.length - 1; i >= 0; i--) {
      if (!nextSet.contains(_keys[i])) {
        final removedKey = _keys[i];
        _remove(
          i,
          (context, animation) =>
              _animate(animation, widget.removedBuilder(context, removedKey, animation)),
          duration,
        );
        _keys.removeAt(i);
      }
    }

    // 2) Insert new keys / fix positions.
    for (var i = 0; i < next.length; i++) {
      if (i >= _keys.length) {
        _keys.insert(i, next[i]);
        _insert(i, duration);
      } else if (_keys[i] != next[i]) {
        final removedKey = _keys[i];
        _remove(
          i,
          (context, animation) =>
              _animate(animation, widget.removedBuilder(context, removedKey, animation)),
          duration,
        );
        _keys.removeAt(i);
        _keys.insert(i, next[i]);
        _insert(i, duration);
      }
    }
  }

  Widget _animate(Animation<double> animation, Widget child) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Motion.emphasized,
      reverseCurve: Motion.emphasizedAccel,
    );
    return FadeTransition(
      opacity: curved,
      child: SizeTransition(
        axis: Axis.vertical,
        sizeFactor: curved,
        alignment: Alignment.topCenter,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sliver) {
      final list = SliverAnimatedList(
        key: _sliverKey,
        initialItemCount: _keys.length,
        itemBuilder: (context, index, animation) => _animate(
          animation,
          widget.itemBuilder(context, index, _keys[index], animation),
        ),
      );
      final padding = widget.padding;
      if (padding == null) return list;
      return SliverPadding(padding: padding, sliver: list);
    }
    return AnimatedList(
      key: _listKey,
      initialItemCount: _keys.length,
      controller: widget.controller,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      itemBuilder: (context, index, animation) => _animate(
        animation,
        widget.itemBuilder(context, index, _keys[index], animation),
      ),
    );
  }
}

bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
