import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../ui/home/home_page.dart';
import '../ui/workspace/desktop_workspace.dart';

/// Picks the desktop workspace or the mobile home page based on the platform.
class RootShell extends StatelessWidget {
  const RootShell({super.key});

  static bool isDesktopPlatform(TargetPlatform platform) {
    return switch (platform) {
      TargetPlatform.linux || TargetPlatform.windows || TargetPlatform.macOS => true,
      _ => false,
    };
  }

  @override
  Widget build(BuildContext context) {
    return isDesktopPlatform(defaultTargetPlatform)
        ? const DesktopWorkspace()
        : const HomePage();
  }
}
