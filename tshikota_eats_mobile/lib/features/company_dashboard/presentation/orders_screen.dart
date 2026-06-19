import 'package:flutter/material.dart';

class CompanyOrdersScreen extends StatelessWidget {
  const CompanyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: const Center(child: Text('Company orders — Coming soon')),
    );
  }
}
