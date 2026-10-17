import 'package:flutter/widgets.dart';

/// Switch to the next session in the tab order.
class NextSessionIntent extends Intent {
  const NextSessionIntent();
}

/// Switch to the previous session in the tab order.
class PrevSessionIntent extends Intent {
  const PrevSessionIntent();
}

/// Close the currently active session.
class CloseActiveSessionIntent extends Intent {
  const CloseActiveSessionIntent();
}
