extension DateTimeFormatting  on DateTime {
  String get formatted =>
      '${day.toString().padLeft(2, '0')}-'
      '${_monthAbbr(month)}-'
      '$year '
      '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}';

  String _monthAbbr(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
