import 'package:flutter/material.dart';

class DeveloperShell extends StatelessWidget {
  final Widget child;
  const DeveloperShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: child);
  }
}
