import 'package:intl/intl.dart';

String formatDate(DateTime date) {
  return DateFormat('dd MMM yyyy').format(date);
}

String formatTime(DateTime date) {
  return DateFormat('HH:mm').format(date);
}

String formatDateTime(DateTime date) {
  return DateFormat('dd MMM yyyy, HH:mm').format(date);
}

String formatRelativeTime(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return formatDate(date);
}

String todayDateString() {
  return DateFormat('yyyy-MM-dd').format(DateTime.now());
}

String yesterdayDateString() {
  return DateFormat(
    'yyyy-MM-dd',
  ).format(DateTime.now().subtract(const Duration(days: 1)));
}
