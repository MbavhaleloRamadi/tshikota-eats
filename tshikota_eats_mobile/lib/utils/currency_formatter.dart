String formatZAR(int cents) {
  final rands = cents / 100;
  return 'R${rands.toStringAsFixed(2)}';
}
