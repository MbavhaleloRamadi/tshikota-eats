import 'package:flutter/material.dart';
import '../../config/theme.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_outlined,
                size: 64, color: TshikotaTheme.textMuted),
            SizedBox(height: 16),
            Text('Your cart is empty',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text('Browse stores and add items',
                style: TextStyle(color: TshikotaTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}
