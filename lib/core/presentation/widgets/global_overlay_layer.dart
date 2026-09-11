import 'package:flutter/material.dart';

class GlobalOverlayLayer extends StatelessWidget {
  final Widget child;

  const GlobalOverlayLayer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // TODO: Connect to sync state provider
    return Stack(
      children: [
        child,
        // Offline sync states can be displayed here
      ],
    );
  }
}
