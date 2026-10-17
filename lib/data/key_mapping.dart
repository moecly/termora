/// Hardware-key ↔ action mapping model.
///
/// A [KeyMapping] pairs a physical [source] (volume/camera keys on Android)
/// with an [action] (Ctrl, arrow keys, …). Sources are matched against the
/// Android `KeyEvent` key codes listed in [kKeyMappingSources]; actions are
/// resolved against [kKeyMappingActions] and applied by `HardwareKeyService`.
class KeyMapping {
  const KeyMapping({required this.source, required this.action});

  /// One of the `id`s in [kKeyMappingSources].
  final String source;

  /// One of the `id`s in [kKeyMappingActions].
  final String action;

  Map<String, Object?> toJson() => {'source': source, 'action': action};

  factory KeyMapping.fromJson(Map<String, Object?> json) => KeyMapping(
        source: json['source']! as String,
        action: json['action']! as String,
      );

  @override
  bool operator ==(Object other) =>
      other is KeyMapping && other.source == source && other.action == action;

  @override
  int get hashCode => Object.hash(source, action);
}

class KeyMappingSource {
  const KeyMappingSource({
    required this.id,
    required this.label,
    required this.androidKeyCode,
  });

  final String id;
  final String label;
  final int androidKeyCode;
}

class KeyMappingAction {
  const KeyMappingAction({required this.id, required this.label});

  final String id;
  final String label;
}

/// Android `KeyEvent` key codes (`android.view.KeyEvent.KEYCODE_*`).
///
/// `camera` is a two-stage shutter key on some devices; it is offered but never
/// enabled by default.
const kKeyMappingSources = <KeyMappingSource>[
  KeyMappingSource(id: 'volumeDown', label: '音量下', androidKeyCode: 25),
  KeyMappingSource(id: 'volumeUp', label: '音量上', androidKeyCode: 24),
  KeyMappingSource(id: 'volumeMute', label: '静音键', androidKeyCode: 164),
  KeyMappingSource(id: 'camera', label: '相机键', androidKeyCode: 27),
];

const kKeyMappingActions = <KeyMappingAction>[
  KeyMappingAction(id: 'ctrl', label: 'Ctrl'),
  KeyMappingAction(id: 'alt', label: 'Alt'),
  KeyMappingAction(id: 'shift', label: 'Shift'),
  KeyMappingAction(id: 'escape', label: 'Esc'),
  KeyMappingAction(id: 'tab', label: 'Tab'),
  KeyMappingAction(id: 'enter', label: '回车'),
  KeyMappingAction(id: 'backspace', label: '退格'),
  KeyMappingAction(id: 'arrowUp', label: '↑'),
  KeyMappingAction(id: 'arrowDown', label: '↓'),
  KeyMappingAction(id: 'arrowLeft', label: '←'),
  KeyMappingAction(id: 'arrowRight', label: '→'),
  KeyMappingAction(id: 'pageUp', label: 'PgUp'),
  KeyMappingAction(id: 'pageDown', label: 'PgDn'),
  KeyMappingAction(id: 'home', label: 'Home'),
  KeyMappingAction(id: 'end', label: 'End'),
  KeyMappingAction(id: 'delete', label: 'Del'),
];

/// Human-readable label for a mapping source [id]; falls back to the id itself.
String keyMappingSourceLabel(String id) {
  for (final s in kKeyMappingSources) {
    if (s.id == id) return s.label;
  }
  return id;
}

/// Human-readable label for a mapping action [id]; falls back to the id itself.
String keyMappingActionLabel(String id) {
  for (final a in kKeyMappingActions) {
    if (a.id == id) return a.label;
  }
  return id;
}
