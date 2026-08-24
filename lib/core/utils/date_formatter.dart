import 'package:gutgood/core/constants/app_strings.dart';
import 'package:intl/intl.dart';

class DateFormatter {
  static String formatTime(DateTime dateTime) => DateFormat('h:mm a').format(dateTime.toLocal());

  static String formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(local.year, local.month, local.day);

    if (date == today) {
      return AppStrings.today;
    } else if (date == yesterday) {
      return AppStrings.yesterday;
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE').format(local); // e.g., "Monday"
    } else if (local.year == now.year) {
      return DateFormat('MMM d').format(local); // e.g., "Aug 23"
    } else {
      return DateFormat('MMM d, yyyy').format(local); // e.g., "Aug 23, 2023"
    }
  }

  static String formatFull(DateTime dateTime) => '${formatDate(dateTime)} • ${formatTime(dateTime)}';

  static String formatRelative(DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final difference = now.difference(local);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return formatDate(dateTime);
    }
  }
}
